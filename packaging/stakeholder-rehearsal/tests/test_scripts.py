"""Tests for the stakeholder-rehearsal scripts. Run: python3 -m unittest discover -s tests -v

Standard library only. Each test works on a throw-away copy of the worked
example (skills/stakeholder-rehearsal/examples/scooter), so nothing in the repo changes.
"""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "skills" / "stakeholder-rehearsal").is_dir())
SKILL = ROOT / "skills" / "stakeholder-rehearsal"
SCRIPTS = SKILL / "scripts"
EXAMPLE = SKILL / "examples" / "scooter"


def run(script, *args, check=False):
    p = subprocess.run([sys.executable, str(SCRIPTS / script), *map(str, args)],
                       capture_output=True, text=True)
    if check:
        assert p.returncode == 0, p.stderr
    return p


def jl(path):
    return [json.loads(l) for l in Path(path).read_text(encoding="utf-8").splitlines() if l.strip()]


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.run_dir = self.tmp / "run"
        shutil.copytree(EXAMPLE, self.run_dir)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def drop_round(self, n):
        (self.run_dir / "rounds" / f"{n:02d}.jsonl").unlink()


class PickAgents(Base):
    def pick(self, rnd, seed=7):
        return json.loads(run("pick_agents.py", self.run_dir, rnd, "--seed", seed, check=True).stdout)

    def test_round_number_equal_to_seed_value_is_not_swallowed(self):
        for seed in (1, 4, 7):
            self.assertEqual(self.pick(seed, seed)["round"], seed)
        out = run("make_packets.py", self.run_dir, 1, "--seed", 1)
        self.assertEqual(out.returncode, 0, out.stderr)

    def test_deterministic_for_same_seed_and_round(self):
        self.assertEqual(self.pick(2), self.pick(2))

    def test_seed_changes_the_draw_somewhere(self):
        self.assertTrue(any(self.pick(r, 1) != self.pick(r, 2) for r in range(1, 5)))

    def test_never_more_than_cap_and_only_known_agents(self):
        cast = {a["id"] for a in json.loads((self.run_dir / "cast.json").read_text())}
        for r in range(1, 5):
            got = self.pick(r)
            self.assertLessEqual(len(got["active"]), int(0.9 * len(cast)))
            self.assertTrue(set(got["active"]) <= cast)

    def test_respects_active_hours(self):
        cfg = json.loads((self.run_dir / "config.json").read_text())
        cast = {a["id"]: a for a in json.loads((self.run_dir / "cast.json").read_text())}
        for r in range(1, 5):
            got = self.pick(r)
            for aid in got["active"]:
                self.assertIn(got["sim_hour"], cast[aid]["active_hours"])
        self.assertEqual(self.pick(1)["sim_hour"], cfg["start_hour"])

    def test_off_peak_hours_can_yield_nobody(self):
        cfg = json.loads((self.run_dir / "config.json").read_text())
        cfg["start_hour"] = 2
        cfg["off_peak_hours"] = [2]
        (self.run_dir / "config.json").write_text(json.dumps(cfg))
        for seed in range(5):
            self.assertEqual(self.pick(1, seed)["active"], [])


class AppendTurns(Base):
    def setUp(self):
        super().setUp()
        self.drop_round(4)
        for f in (self.run_dir / "turns").glob("*"):
            shutil.rmtree(f)
        self.t4 = self.run_dir / "turns" / "04"
        self.t4.mkdir(parents=True)

    def turn(self, aid, **kw):
        (self.t4 / f"{aid}.json").write_text(json.dumps(kw))

    def test_round_zero_writes_opening_posts(self):
        self.drop_round(0)
        run("append_turns.py", self.run_dir, 0, check=True)
        rows = jl(self.run_dir / "rounds" / "00.jsonl")
        self.assertEqual([r["id"] for r in rows], ["r00#1", "r00#2"])
        self.assertTrue(all(r["action"] == "post" for r in rows))

    def test_valid_turns_get_sequential_ids_in_agent_order(self):
        (self.t4 / "active.json").write_text('["a06","a02"]')
        self.turn("a06", action="like", target="r00#1", content="")
        self.turn("a02", action="post", target=None, content="hello there")
        p = run("append_turns.py", self.run_dir, 4)
        self.assertEqual(p.returncode, 0, p.stderr)
        rows = jl(self.run_dir / "rounds" / "04.jsonl")
        self.assertEqual([(r["id"], r["agent"]) for r in rows], [("r04#1", "a02"), ("r04#2", "a06")])

    def test_ids_use_two_digit_round(self):
        (self.t4 / "active.json").write_text('["a02"]')
        self.turn("a02", action="post", content="x y z")
        run("append_turns.py", self.run_dir, 4)
        self.assertEqual(jl(self.run_dir / "rounds" / "04.jsonl")[0]["id"], "r04#1")

    def test_invalid_action_target_and_missing_file_become_nothing(self):
        (self.t4 / "active.json").write_text('["a02","a03","a04","a05"]')
        self.turn("a02", action="dance", target=None, content="")
        self.turn("a03", action="like", target="r99#9", content="")
        self.turn("a04", action="post", content="")
        # a05 has no file
        p = run("append_turns.py", self.run_dir, 4)
        self.assertEqual(p.returncode, 1)
        self.assertEqual(p.stderr.count("WARNING"), 4)
        self.assertTrue(all(r["action"] == "nothing" for r in jl(self.run_dir / "rounds" / "04.jsonl")))

    def test_post_target_is_cleared(self):
        (self.t4 / "active.json").write_text('["a02"]')
        self.turn("a02", action="post", target="r00#1", content="a plain post")
        run("append_turns.py", self.run_dir, 4)
        self.assertIsNone(jl(self.run_dir / "rounds" / "04.jsonl")[0]["target"])

    def test_refuses_to_overwrite_a_log(self):
        (self.t4 / "active.json").write_text("[]")
        run("append_turns.py", self.run_dir, 4, check=True)
        p = run("append_turns.py", self.run_dir, 4)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("append-only", p.stderr + p.stdout)

    def test_injections_come_first(self):
        cfg = json.loads((self.run_dir / "config.json").read_text())
        cfg["injections"] = [{"round": 4, "agent": "a05", "content": "breaking news", "why": "test"}]
        (self.run_dir / "config.json").write_text(json.dumps(cfg))
        (self.t4 / "active.json").write_text('["a02"]')
        self.turn("a02", action="quote", target="r00#1", content="reacting")
        run("append_turns.py", self.run_dir, 4)
        rows = jl(self.run_dir / "rounds" / "04.jsonl")
        self.assertEqual((rows[0]["agent"], rows[0]["content"]), ("a05", "breaking news"))
        self.assertEqual(rows[1]["id"], "r04#2")


class MakePackets(Base):
    def setUp(self):
        super().setUp()
        self.drop_round(4)

    def test_writes_prompts_and_active_list_for_the_active_agents(self):
        out = json.loads(run("make_packets.py", self.run_dir, 4, "--seed", 7, check=True).stdout)
        t = self.run_dir / "turns" / "04"
        self.assertEqual(json.loads((t / "active.json").read_text()), out["active"])
        for aid in out["active"]:
            text = (t / f"{aid}.prompt.md").read_text()
            self.assertIn("== WHO YOU ARE ==", text)
            self.assertIn(str(t / f"{aid}.json"), text)
            self.assertIn("Do not invent dates", text)

    def test_same_seed_reproduces_the_recorded_round(self):
        out = json.loads(run("make_packets.py", self.run_dir, 4, "--seed", 7, check=True).stdout)
        recorded = [r["agent"] for r in jl(EXAMPLE / "rounds" / "04.jsonl")]
        self.assertEqual(out["active"], sorted(set(recorded)))

    def test_feed_excludes_posts_the_agent_already_acted_on_and_its_own(self):
        run("make_packets.py", self.run_dir, 4, "--seed", 7, check=True)
        text = (self.run_dir / "turns" / "04" / "a06.prompt.md").read_text()
        feed = text.split("== YOUR FEED")[1].split("== YOUR TURN")[0]
        rows = jl(self.run_dir / "rounds" / "01.jsonl") + jl(self.run_dir / "rounds" / "02.jsonl")
        acted = {r["target"] for r in jl(EXAMPLE / "rounds" / "01.jsonl") + jl(EXAMPLE / "rounds" / "02.jsonl")
                 + jl(EXAMPLE / "rounds" / "03.jsonl") if r["agent"] == "a06" and r["target"]}
        for pid in acted:
            self.assertNotIn(f"[{pid}]", feed)
        own = {r["id"] for r in jl(EXAMPLE / "rounds" / "03.jsonl") if r["agent"] == "a06"}
        for pid in own:
            self.assertNotIn(f"[{pid}]", feed)
        self.assertTrue(rows)

    def test_scheduled_injection_appears_in_feed_with_its_future_id(self):
        cfg = json.loads((self.run_dir / "config.json").read_text())
        cfg["injections"] = [{"round": 4, "agent": "a05", "content": "SCHEDULED-NEWS-ITEM", "why": "t"}]
        (self.run_dir / "config.json").write_text(json.dumps(cfg))
        out = json.loads(run("make_packets.py", self.run_dir, 4, "--seed", 7, check=True).stdout)
        seen = [a for a in out["active"] if a != "a05" and "[r04#1] Harborview Courier: \"SCHEDULED-NEWS-ITEM\""
                in (self.run_dir / "turns" / "04" / f"{a}.prompt.md").read_text()]
        self.assertTrue(seen)


class LogView(Base):
    def test_stats_search_timeline_thread(self):
        stats = run("log_view.py", self.run_dir, "stats", check=True).stdout
        self.assertIn("quote=15", stats)
        self.assertIn("r03#1", run("log_view.py", self.run_dir, "search", "councillors", check=True).stdout)
        self.assertIn("Transport Office", run("log_view.py", self.run_dir, "timeline", "a01", check=True).stdout)
        self.assertIn("r01#1", run("log_view.py", self.run_dir, "thread", "r00#1", check=True).stdout)

    def test_search_without_match(self):
        self.assertIn("no matches", run("log_view.py", self.run_dir, "search", "zzzzzz", check=True).stdout)


class MakeInterview(Base):
    def test_prompt_contains_persona_history_and_questions(self):
        run("make_interview.py", self.run_dir, "a06", "Why?", "What next?", check=True)
        text = (self.run_dir / "interviews" / "a06.prompt.md").read_text()
        self.assertIn("Marco", text)
        self.assertIn("1. Why?", text)
        self.assertIn("2. What next?", text)
        self.assertIn("[r01#4]", text)  # his own first action
        self.assertIn(str(self.run_dir / "interviews" / "a06.md"), text)


class EstimateCost(Base):
    def test_matches_the_calls_actually_recorded_for_the_example(self):
        out = run("estimate_cost.py", self.run_dir, "--seed", 7, "--interviews", 2, "--baseline", check=True).stdout
        actual = sum(len([r for r in jl(EXAMPLE / "rounds" / f"{n:02d}.jsonl")]) for n in range(1, 5))
        injected = 1  # round 3 injection is logged but is not a sub-agent call
        self.assertIn(f"turn calls: {actual - injected}", out)
        self.assertIn("TOTAL sub-agent calls: 22", out)

    def test_warns_above_sixty(self):
        cfg = json.loads((self.run_dir / "config.json").read_text())
        cfg["total_rounds"] = 40
        cfg["agents_per_hour"] = [4, 5]
        cfg["minutes_per_round"] = 60
        cfg["peak_hours"] = list(range(24))
        (self.run_dir / "config.json").write_text(json.dumps(cfg))
        cast = json.loads((self.run_dir / "cast.json").read_text())
        for a in cast:
            a["active_hours"] = list(range(24))
            a["activity_level"] = 1.0
        (self.run_dir / "cast.json").write_text(json.dumps(cast))
        self.assertIn("go-ahead", run("estimate_cost.py", self.run_dir, check=True).stdout)

    def test_seed_value_equal_to_other_args_is_not_swallowed(self):
        self.assertEqual(run("estimate_cost.py", self.run_dir, "--seed", 1, "--interviews", 1).returncode, 0)


class MakeBaseline(Base):
    def test_prompt_has_question_seed_files_and_output_path(self):
        (self.run_dir / "brief.md").write_text("Question: what happens?", encoding="utf-8")
        run("make_baseline.py", self.run_dir, self.run_dir / "seed.md", check=True)
        text = (self.run_dir / "baseline.prompt.md").read_text()
        self.assertIn("what happens?", text)
        self.assertIn(str(self.run_dir / "seed.md"), text)
        self.assertIn(str(self.run_dir / "baseline.md"), text)
        self.assertIn("Do not invent", text)


class VerifyQuotes(Base):
    NOTICE = (SKILL / "references" / "report-notice.md").read_text(encoding="utf-8").strip()

    def verify(self, report_text, notice=True):
        f = self.tmp / "r.md"
        f.write_text(("# T\n\n" + self.NOTICE + "\n\n" if notice else "") + report_text, encoding="utf-8")
        return run("verify_quotes.py", self.run_dir, f)

    def test_missing_notice_fails_and_flag_skips_it(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        text = f"> {row['content']}\n> — X [{row['id']}]\n"
        p = self.verify(text, notice=False)
        self.assertEqual(p.returncode, 1)
        self.assertIn("MISSING NOTICE", p.stdout)
        f = self.tmp / "n.md"
        f.write_text(text, encoding="utf-8")
        self.assertEqual(run("verify_quotes.py", self.run_dir, f, "--no-notice").returncode, 0)

    def test_notice_buried_late_does_not_count(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        filler = "\n".join(f"line {i}" for i in range(20))
        f = self.tmp / "b.md"
        f.write_text(f"# T\n\n{filler}\n\n{self.NOTICE}\n\n> {row['content']}\n> — X [{row['id']}]\n", encoding="utf-8")
        self.assertEqual(run("verify_quotes.py", self.run_dir, f).returncode, 1)

    def test_shipped_example_report_passes(self):
        p = run("verify_quotes.py", self.run_dir)
        self.assertEqual(p.returncode, 0, p.stdout)

    def test_exact_quote_with_matching_id_passes(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        p = self.verify(f"> {row['content']}\n> — X [{row['id']}]\n")
        self.assertEqual(p.returncode, 0, p.stdout)

    def test_ellipsis_in_order_passes(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        words = row["content"].split()
        p = self.verify(f"> {' '.join(words[:4])} … {' '.join(words[-4:])}\n> — X [{row['id']}]\n")
        self.assertEqual(p.returncode, 0, p.stdout)

    def test_altered_quote_fails(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        p = self.verify(f"> {row['content']} and then something invented\n> — X [{row['id']}]\n")
        self.assertEqual(p.returncode, 1)

    def test_quote_from_another_post_than_cited_fails(self):
        rows = jl(self.run_dir / "rounds" / "01.jsonl")
        p = self.verify(f"> {rows[0]['content']}\n> — X [{rows[1]['id']}]\n")
        self.assertEqual(p.returncode, 1)

    def test_stitched_quote_across_posts_fails(self):
        rows = jl(self.run_dir / "rounds" / "01.jsonl")
        a, b = rows[0]["content"].split()[:5], rows[1]["content"].split()[-5:]
        p = self.verify(f"> {' '.join(a)} … {' '.join(b)}\n> — X [{rows[0]['id']}]\n")
        self.assertEqual(p.returncode, 1)

    def test_missing_citation_and_unknown_id_fail(self):
        row = jl(self.run_dir / "rounds" / "01.jsonl")[0]
        self.assertEqual(self.verify(f"> {row['content']}\n").returncode, 1)
        self.assertEqual(self.verify(f"> {row['content']}\n> — X [r98#7]\n").returncode, 1)

    def test_interview_quote_passes_under_iv_id(self):
        text = (self.run_dir / "interviews" / "a06.md").read_text()
        line = next(l for l in text.splitlines() if l.startswith("A2:"))[4:]
        p = self.verify(f"> {line}\n> — Marco [iv:a06]\n")
        self.assertEqual(p.returncode, 0, p.stdout)


if __name__ == "__main__":
    unittest.main()
