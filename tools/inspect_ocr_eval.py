
import json, os
p = os.path.join(os.environ.get("TEMP", ""), "ocr-eval-extract", "ocr_eval.json")
with open(p, encoding="utf-8") as f:
    data = json.load(f)
for case in data["cases"]:
    print("==", case["id"])
    for field, info in case["checks"].items():
        if not info["ok"]:
            print("  FAIL", field, "expected:", repr(info["expected"]), "actual:", repr(info["actual"]))
    if case["hallucinations"]:
        print("  HALLUCINATION:", case["hallucinations"])
    print("  raw:", " / ".join(case["rawText"].split("\n")))
