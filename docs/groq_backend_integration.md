# Groq Backend Integration (HireCraft)

## Security first
- Do not hardcode API keys in Flutter or backend source files.
- Store the Groq key in backend environment variables only.
- If a key was shared publicly, rotate it immediately in Groq console.

## 1) Backend env setup
Create a `.env` file for backend service:

```env
GROQ_API_KEY=your_new_rotated_key_here
GROQ_MODEL=llama-3.3-70b-versatile
PORT=8080
```

## 2) Install backend dependencies (Node/Express example)
```bash
npm install express cors dotenv zod
```

## 3) Add prompt contract (exact structure)
Use this system prompt in backend:

```text
You are an expert resume writer and ATS optimization specialist.

Your job is to transform raw user-provided resume data into a highly professional, concise, achievement-oriented resume.

CRITICAL RULES:
- You MUST preserve the JSON structure exactly.
- You MUST NOT add or remove fields.
- You MUST NOT return markdown.
- You MUST NOT return explanations.
- You MUST ONLY return valid JSON.
- Improve wording but keep original meaning.
- Expand weak bullet points into measurable achievements when reasonable.
- Use strong action verbs.
- Optimize for ATS readability.
- Avoid buzzwords and fluff.
- Each bullet point should be 8–22 words.
- Prefer quantified impact (%, numbers, scale) when realistic.
- If data is insufficient, improve wording without inventing unrealistic metrics.
- Maintain professional tone based on target role and experience level.

WRITING STYLE:
- Concise and modern
- Results-oriented
- No first person pronouns
- No emojis
- No decorative characters
- No personal opinions
```

Build user message from request payload:

```text
Transform the following resume data.

User Context:
Career Level: {{career_level}}
Target Role: {{target_role}}
Industry: {{industry}}
Preferred Tone: {{tone}}

Optional Job Description:
{{job_description_or_null}}

Resume Data:
{{resume_json}}

Return the improved resume in the exact same JSON structure.
```

## 4) Backend route shape expected by app
App already sends requests to:
- `POST /resume/generate`
- `POST /resume/optimize`

Body fields from app:
- `resumeData` (required)
- `career_level` (optional)
- `target_role` (optional)
- `industry` (optional)
- `tone` (optional)
- `job_description_or_null` (optional for generate)
- `jobDescription` (required for optimize route)

## 5) JSON safety + retry (recommended)
In backend, after receiving model text response:
1. Attempt `JSON.parse(responseText)`.
2. If parse fails, retry once with appended repair instruction:
   - `Return only valid JSON. Do not include backticks.`
3. If second attempt fails, return `502` with clear error payload.

## 6) Response contract to Flutter
For `POST /resume/generate`, return either:

```json
{ "variations": ["{...json...}", "{...json...}", "{...json...}"] }
```

or

```json
["{...json...}", "{...json...}", "{...json...}"]
```

For `POST /resume/optimize`, return either:

```json
{ "suggestions": ["..."] }
```

or

```json
["...", "..."]
```

## 7) Flutter run command
Set backend URL in Flutter at runtime:

```bash
flutter run --dart-define=AI_BACKEND_URL=http://YOUR_BACKEND_HOST:8080
```

## 8) Quick test checklist
1. Onboarding completed (career level/role/industry/tone stored).
2. Open Resume Generate page and run AI generation.
3. Open Optimize page, paste JD, and generate suggestions.
4. Verify backend logs include context fields.
5. Verify output JSON parses successfully and keeps original structure.
