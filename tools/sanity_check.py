
import json, plistlib, os, sys, glob
root = r"C:\Users\Kgy\Documents\1_上课资料\大三上\移动应用开发\CamCardReplica"
print("repo:", root)

# plist
with open(os.path.join(root, "App", "Info.plist"), "rb") as f:
    pl = plistlib.load(f)
print("Info.plist OK, keys:", len(pl))

# json
with open(os.path.join(root, "sample_data", "ground_truth.json"), encoding="utf-8") as f:
    gt = json.load(f)
print("ground_truth OK, cards:", len(gt))

# yaml
try:
    import yaml
    for name in ["project.yml", ".github/workflows/ios.yml"]:
        with open(os.path.join(root, name), encoding="utf-8") as f:
            data = yaml.safe_load(f)
        print("YAML OK:", name, "top keys:", list(data.keys())[:8])
except ImportError:
    print("PyYAML not installed; skip yaml validation")
except Exception as e:
    print("YAML ERROR:", e)

# naive brace balance for swift files
bad = []
for path in glob.glob(os.path.join(root, "**", "*.swift"), recursive=True):
    with open(path, encoding="utf-8") as f:
        src = f.read()
    # strip strings/comments crudely
    depth = 0
    in_str = False
    in_comment = False
    i = 0
    while i < len(src):
        ch = src[i]
        nxt = src[i+1] if i+1 < len(src) else ""
        if in_comment:
            if ch == "*" and nxt == "/":
                in_comment = False; i += 2; continue
            i += 1; continue
        if in_str:
            if ch == "\\":
                i += 2; continue
            if ch == '"':
                in_str = False
            i += 1; continue
        if ch == "/" and nxt == "*":
            in_comment = True; i += 2; continue
        if ch == '"':
            in_str = True; i += 1; continue
        if ch == "{": depth += 1
        elif ch == "}": depth -= 1
        i += 1
    if depth != 0 or in_str or in_comment:
        bad.append((os.path.relpath(path, root), depth, in_str, in_comment))
print("swift brace check:", "OK" if not bad else bad)
