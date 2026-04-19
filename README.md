# DailyDev

Tuist-based Apple platform workspace for:

- iOS (iPhone + iPad)
- macOS
- Shared feature and core modules

## Structure

- `App/iOS`: iPhone + iPad app target
- `App/macOS`: macOS app target
- `Modules/Core`: shared app models and environment types
- `Modules/Entity`: pure business entities shared across app layers
- `Modules/Domain`: use cases and repository contracts
- `Modules/Data`: repository implementations and data sources
- `Modules/DesignSystem`: shared colors and typography helpers
- `Modules/Features`: TCA-based feature module containing `Home` and future screen features

## Architecture Notes

- TCA feature/dependency conventions are documented in [docs/TCA_ARCHITECTURE.md](/Users/kim-jeongwon/Desktop/DailyDev/docs/TCA_ARCHITECTURE.md)

## Next steps

1. Run `tuist generate`
2. Open the generated workspace
3. Add more modules under `Modules/`
4. Split iPhone/iPad UI inside feature modules when needed
