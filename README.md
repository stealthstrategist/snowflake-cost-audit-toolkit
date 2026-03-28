# Snowflake Cost Audit Toolkit

A set of SQL scripts to identify and eliminate Snowflake credit waste in any environment.

These are the exact queries used to find $3,000–$8,000/month in recoverable spend across Fintech and SaaS data stacks.

---

## What's in this repo

| File | What it does |
|------|-------------|
| `warehouse_audit.sql` | Ranks warehouses by credit spend — finds your biggest cost drivers in one query |
| `resource_monitor.sql` | Ready-to-run SQL to set up spend caps and alerts |
| `kill_list_template.md` | Template for ranking waste by dollar impact |

---

## The 4 most common sources of Snowflake waste

**1. Warehouses sized too large**
X-LARGE warehouses running dashboard refreshes that a SMALL could handle for 1/16th the cost. Never gets revisited after initial setup.

**2. Auto-suspend set too high**
10–15 minute suspends on warehouses that get hit sporadically. Credits burn while the warehouse idles waiting for the next query.

**3. No resource monitors**
Without monitors, one rogue query or misconfigured job can burn a month of credits overnight with zero alerts.

**4. Full table scans**
Queries hitting millions of rows without clustering keys force expensive full scans on every run.

---

## Quick start

Run `warehouse_audit.sql` first. It queries `SNOWFLAKE.ACCOUNT_USAGE` and ranks your warehouses by total credit spend. The top result is almost always where your money is going.

You'll need `ACCOUNTADMIN` or a role with access to `SNOWFLAKE.ACCOUNT_USAGE`.

---

## Want this done for you?

Fixed-scope async audit — no calls, no meetings. Delivered to your GitHub in 5 days for $2,500.

**Money-back guarantee:** if I don't find at least $2,500/month in recoverable waste, you pay nothing.

[stealthstrategist.co](https://stealthstrategist.co)

---

## License

MIT — use these scripts freely in your own environment.
