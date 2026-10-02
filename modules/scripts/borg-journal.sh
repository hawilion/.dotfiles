#!/usr/bin/env bash
exec journalctl -u borg-backup-lenovo.service -e -f
