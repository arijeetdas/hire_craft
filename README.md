# hire_craft

HireCraft is a Flutter resume builder with AI generation, ATS scoring, templates, and export.

## Run with AI backend

This app expects an AI backend URL through dart define:

```bash
flutter run --dart-define=AI_BACKEND_URL=http://YOUR_BACKEND_HOST:8080
```

### Important security note

- Never commit AI provider API keys to this repository.
- Keep provider keys in backend environment variables only.

## Groq integration guide

Step-by-step backend + app integration is documented here:

- [docs/groq_backend_integration.md](docs/groq_backend_integration.md)
