# Changelog

## 0.2.0

Parity release with `cashramp-sdk-node` 0.0.13.

### Added

- `initiate_hosted_payment` now accepts an optional `metadata:` hash, forwarded as the GraphQL `$metadata: JSON` variable on `initiateHostedPayment`.
- `add_payment_method` now accepts an optional `ownership:` argument (`"first_party"` or `"third_party"`), forwarded as the GraphQL `$ownership: P2PPaymentMethodOwnership` variable.
- `initiate_ramp_quote_deposit` now accepts an optional `onchain_transfer_info:` hash (`:address`, `:cryptocurrency`, `:network`) for onchain stablecoin delivery, forwarded as `$onchainTransferInfo: OnchainTransferInfo`.
- `CHANGELOG.md` and gemspec metadata pointing at the public GitHub and docs URLs.

### Changed

- `ramp_quote` now defaults `payment_type:` to `"deposit"` when nil/omitted, matching the Node SDK.
- `RAMP_QUOTE` query now declares `$paymentType: PaymentTypeType` (optional), matching the Node SDK.
- `initiate_hosted_payment` makes `currency:`, `reference:`, `redirect_url:`, and `metadata:` optional (currency defaults to `"usd"`).
- `withdraw_onchain` strips nil values from the GraphQL variables hash for consistency with the rest of the client.
- README rewritten to mirror the Node SDK's structure (Quick Start, Hosted Payments, Direct Ramp deposits/withdrawals, onchain transfer info, API reference).
- Bumped to `0.2.0`.

### Fixed

- `INITIATE_HOSTED_PAYMENT` previously sent the GraphQL variable as `redirect_url`; the API expects `redirectUrl`. The client now sends the correct camelCase key.
- `ADD_PAYMENT_METHOD` previously declared `$paymentMethodType: ID!` and passed `p2pPaymentMethodType: $paymentMethodType` to the field; both are wrong against the current Cashramp schema. The mutation now declares `$paymentMethodType: String!` and passes `paymentMethodType: $paymentMethodType`, matching the Node SDK.
- Removed the dead class-level `HTTParty.headers` block in `Cashramp::Client` that interpolated `@secret_key` at class-load time (always `nil`). The per-request `Authorization` header in `send_request` was already doing the right thing.
- `lib/cashramp.rb` now requires `cashramp/version`, so `Cashramp::VERSION` is always loaded.
