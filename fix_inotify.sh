#!/bin/bash

# Fix inotify watch limit for Streamlit
# Solves: OSError: [Errno 28] inotify watch limit reached

echo "=================================="
echo "Fix inotify watch limit"
echo "=================================="
echo ""

CURRENT=$(cat /proc/sys/fs/inotify/max_user_watches)
echo "Current limit: $CURRENT"
echo ""

if [ "$CURRENT" -lt "524288" ]; then
    echo "Limit is too low. Attempting to increase..."
    echo ""

    # Method 1: Temporary increase (until reboot)
    echo "Method 1: Temporary increase (until reboot)"
    echo "Command: sudo sysctl -w fs.inotify.max_user_watches=524288"
    echo ""

    # Try to execute with sudo
    if sudo sysctl -w fs.inotify.max_user_watches=524288 2>/dev/null; then
        echo "✓ Temporarily increased to 524288"
        echo ""
    else
        echo "✗ Temporary increase failed (need sudo)"
        echo ""
    fi

    # Method 2: Permanent increase
    echo "Method 2: Permanent increase (recommended)"
    echo "Commands:"
    echo "  sudo bash -c 'echo \"fs.inotify.max_user_watches=524288\" >> /etc/sysctl.conf'"
    echo "  sudo sysctl -p"
    echo ""

    # Try to execute
    if sudo bash -c 'echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf' 2>/dev/null && \
       sudo sysctl -p 2>/dev/null; then
        echo "✓ Permanently increased to 524288"
        echo ""
        NEW=$(cat /proc/sys/fs/inotify/max_user_watches)
        echo "New limit: $NEW"
    else
        echo "✗ Permanent increase failed (need sudo)"
        echo ""
        echo "If you don't have sudo access, ask your system administrator to run:"
        echo "  echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf"
        echo "  sysctl -p"
    fi
else
    echo "✓ Limit is already sufficient ($CURRENT >= 524288)"
fi

echo ""
echo "Alternative: If you can't modify system settings,"
echo "use Streamlit with file monitoring disabled:"
echo "  streamlit run --logger.level=error emo_hallo/Main.py"
echo ""
