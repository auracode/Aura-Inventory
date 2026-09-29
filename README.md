# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Inventory workflow

- Dashboard (/) shows catalogue definitions, current IN/OUT unit counts, and the latest 15 batches.
- Creation (/creation) defines name, type, optional variant, origin, and item condition. It does not add stock.
- Inward (/inward) selects one catalogue item per batch. Scan unique physical-unit barcodes, remove accidental scans, then save.
- Outward (/outward) requires Taken By; Client Code is optional. Scan existing IN units and save together.
- Barcode scanners should send Enter after each barcode. Without JavaScript, enter one barcode per line.
- Stock changes only when a batch is saved. Duplicate barcodes and invalid IN/OUT transitions reject the entire batch.
- First movement must be IN. Returns reuse the same unit and barcode and append movement history.
- Batch pages show scan times and saved time (UTC). Manual entries use the save time.
- Open an item to inspect its physical units and movement history. Items with units cannot be deleted.
- Condition remains on the catalogue Item for now; IN/OUT belongs to each physical unit.
- Unsaved scan lists exist only in the current page: save or finish the batch before navigating away.

### Run locally

Use Ruby 4.0.7, Rails 8.1.4, and the existing PostgreSQL setup.
Configure POSTGRES_PASSWORD in your terminal environment, then from this repository run:

    bundle exec ruby bin/rails db:migrate
    bundle exec ruby bin/rails test
    bundle exec ruby bin/rails server

Open http://localhost:3000/.

The workflow migration adds item names (existing names are filled from item_type),
inventory_units, movement_batches, and movements. Do not rerun the old experimental
replacement migration; apply pending migrations normally.

### Verification on 29 September 2026

Migration and the Rails suite were verified against an isolated PostgreSQL 18
database because the agent session did not have the development database password.
A temporary, external Windows glob workaround was used for the sandbox's Ruby
runtime; installed gems and app runtime configuration were not changed.
The development database still needs its pending migration applied in a configured terminal.