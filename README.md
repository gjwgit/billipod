# Billi Pod

## Recurring Payments

The workflow is:

+ While untouched — instance is auto-generated, gets refreshed
  whenever the template changes
+ Once you fill in any details (notification received, payment
  scheduled, note edited) — it becomes independent and is never
  overwritten again
+ Once moved to Scheduled or Past — it's fully independent

The practical implication is that the auto-generated instances are
really just "placeholder reminders" until you act on them. The moment
you start filling them in they become proper individual records. This
means you never lose data you've manually entered, but pristine future
instances always stay in sync with the template.

One thing worth knowing: if you change the template's dueDate
(i.e. the anchor date), all untouched instances will be regenerated
with new dates based on the new anchor. Instances you've already
touched keep their original dates.
