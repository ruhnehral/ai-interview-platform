#!/usr/bin/env bash
# Seeded fault test — reproduces the proof in 05-monozukuri-execution.md.
#
# Breaks the two P0 rules on a scratch branch, runs both suites so you can watch
# them fail, then reverts with the revert commit left in history.
#
# Usage:  ./assessment/step5/seeded-fault.sh
# Requires: a Postgres test database for the API suite, and `npm install` in web/.

set -uo pipefail
cd "$(dirname "$0")/../.."

BRANCH="chore/seeded-fault-$(date +%s)"
echo "==> Creating scratch branch $BRANCH"
git checkout -b "$BRANCH" || exit 1

echo "==> Seeding fault 1/3: an unknown end_reason falls back to success (web)"
perl -0pi -e 's/if \(!reason\) return "error";/if (!reason) return "completed"; \/\/ SEEDED FAULT/' \
  web/src/lib/interviewOutcome.ts

echo "==> Seeding fault 2/3: every skill counts as discussed (api)"
perl -0pi -e 's/      map\.state\.to_s != NOT_DISCUSSED_STATE/      true # SEEDED FAULT/' \
  api/app/services/portfolios/coverage_lookup.rb

echo "==> Seeding fault 3/3: a missing level collapses back to L1 (api)"
perl -0pi -e 's/      return nil if number\.nil\?/      number = value.to_i if number.nil? # SEEDED FAULT/' \
  api/app/services/portfolios/skill_payload.rb

git commit -qam "test(seeded-fault): break the P0 rules to prove the tests catch them"

echo
echo "==> Running the API suite (expected: FAILING)"
( cd api && bundle exec rspec spec/services/portfolios spec/lib )

echo
echo "==> Running the web suite (expected: FAILING)"
( cd web && npm test )

echo
echo "==> Reverting the seeded fault (history stays visible)"
git revert --no-edit HEAD

echo
echo "==> Re-running both suites (expected: PASSING)"
( cd api && bundle exec rspec spec/services/portfolios spec/lib )
( cd web && npm test )

echo
echo "Done. Scratch branch: $BRANCH"
git log --oneline -3
