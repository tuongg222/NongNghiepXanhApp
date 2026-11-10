from pathlib import Path

p = Path("analysis_options.yaml")
text = p.read_text() if p.exists() else "include: package:flutter_lints/flutter.yaml\n"

if "backup_before_upgrade/**" not in text:
    text += "\n# Ignore old backup code\nanalyzer:\n  exclude:\n    - backup_before_upgrade/**\n"

p.write_text(text)
print("Da bo qua backup_before_upgrade/")
