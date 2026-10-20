#!/usr/bin/env python3
"""Deterministic ADB substitute; unexpected commands fail, never reach hardware."""
import json
import os
import sys
from pathlib import Path

args = sys.argv[1:]
with Path(os.environ['FAKE_ADB_LOG']).open('a') as log:
    log.write(json.dumps(args) + '\n')
if args == ['start-server']:
    sys.exit(0)
if args[:3] != ['-s', 'test-tv', 'shell']:
    sys.exit(91)
responses = json.loads(Path(os.environ['FAKE_ADB_RESPONSES']).read_text())
command = ' '.join(args[3:])
if command not in responses:
    print('unexpected command: ' + command, file=sys.stderr)
    sys.exit(92)
result = responses[command]
print(result['out'])
sys.exit(result.get('code', 0))
