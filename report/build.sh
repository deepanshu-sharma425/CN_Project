#!/bin/bash
# Rebuild both PDFs from their HTML sources (needs Google Chrome).
cd "$(dirname "$0")" || exit 1
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
build() {  # html source, pdf output
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$2" "file://$PWD/$1" 2>/dev/null
  echo "Wrote $PWD/$2"
}
build report.html      Team_Nova_Phase1_Report.pdf
build demo_report.html Team_Nova_Demo_Report.pdf
build phase2_report.html Team_Nova_Phase2_Report.pdf
