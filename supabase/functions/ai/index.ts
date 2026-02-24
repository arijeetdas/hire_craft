// @ts-ignore: Deno remote import is resolved by Supabase Edge runtime.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

declare const Deno: {
  env: {
    get: (key: string) => string | undefined;
  };
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const systemPrompt = `
You are an expert resume writer and ATS optimization specialist.

Your job is to transform raw user-provided resume data into a highly professional, concise, achievement-oriented resume.

CRITICAL RULES:
- You MUST preserve the JSON structure exactly.
- You MUST NOT add or remove fields.
- You MUST NOT return markdown.
- You MUST NOT return explanations.
- You MUST ONLY return valid JSON.
- Rewrite weak/poorly written input into polished professional language.
- Keep factual intent, but do not copy low-quality phrasing verbatim.
- Expand weak bullet points into measurable achievements when reasonable.
- Use strong action verbs.
- Optimize for ATS readability.
- Avoid buzzwords and fluff.
- Each bullet point should be 8–22 words.
- Prefer quantified impact when realistic.
- If data is insufficient, improve wording without inventing unrealistic metrics.
- Maintain professional tone based on target role and experience level.
- Keep output in an ATS-friendly professional resume style:
  - Strong role-specific summary
  - Impact-first bullets in experience/projects
  - Clean concise phrasing without decorative symbols
- Treat provided input as rough notes that require normalization and rewriting.
`;

function templateToneInstruction(template: any): string {
  if (!template || typeof template !== "object") {
    return "Use professional concise tone.";
  }

  const tone = typeof template.aiTone === "string" ? template.aiTone : "professional concise";
  const summaryStyle = typeof template.aiSummaryStyle === "string"
    ? template.aiSummaryStyle
    : "2-3 lines, role-aligned, ATS keyword rich";
  const bulletStyle = typeof template.aiBulletStyle === "string"
    ? template.aiBulletStyle
    : "one-line impact bullets with measurable outcomes";
  const keywordBias = typeof template.aiKeywordBias === "string"
    ? template.aiKeywordBias
    : "balanced";
  const name = typeof template.name === "string" ? template.name : "selected template";
  const sectionOrder = Array.isArray(template.sectionOrder)
    ? template.sectionOrder.map((x: unknown) => String(x)).join(", ")
    : "summary, experience, projects, education, skills";

  return `Template: ${name}. Writing tone: ${tone}. Summary style: ${summaryStyle}. Bullet style: ${bulletStyle}. Keyword bias: ${keywordBias}. Preferred section order: ${sectionOrder}.`;
}

function jsonResponse(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizePath(pathname: string) {
  return pathname.replace(/^\/+|\/+$/g, "");
}

function generationTemperature(template: any, strongRewrite: boolean): number {
  if (strongRewrite) {
    return 0.26;
  }
  if (!template || typeof template !== "object") {
    return 0.22;
  }
  if (template.id === "modern-clean") {
    return 0.16;
  }
  return 0.2;
}

async function callGroq(
  messages: Array<{ role: "system" | "user"; content: string }>,
  options?: { temperature?: number },
) {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  const model = Deno.env.get("GROQ_MODEL") || "llama-3.3-70b-versatile";
  const temperature = options?.temperature ?? 0.22;

  if (!apiKey) {
    throw new Error("Missing GROQ_API_KEY secret");
  }

  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature,
      messages,
    }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Groq error ${res.status}: ${errorText}`);
  }

  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content;
  if (!text || typeof text !== "string") {
    throw new Error("Groq returned empty response");
  }
  return text.trim();
}

async function parseJsonWithRepair(
  baseMessages: Array<{ role: "system" | "user"; content: string }>,
  firstText: string,
  options?: { temperature?: number },
) {
  try {
    return JSON.parse(firstText);
  } catch {
    const repaired = await callGroq([
      ...baseMessages,
      {
        role: "user",
        content: "Return only valid JSON. Do not include backticks. Do not include explanations.",
      },
    ], options);
    return JSON.parse(repaired);
  }
}

function toJsonString(value: unknown): string {
  return typeof value === "string" ? value : JSON.stringify(value);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const path = normalizePath(new URL(req.url).pathname);
  const isGenerate = path.endsWith("resume/generate");
  const isOptimize = path.endsWith("resume/optimize");
  const isAts = path.endsWith("resume/ats");

  if (!isGenerate && !isOptimize && !isAts) {
    return jsonResponse(404, { error: "Route not found" });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body" });
  }

  const resumeData = body?.resumeData;
  const careerLevel = body?.career_level ?? "Not provided";
  const targetRole = body?.target_role ?? "Not provided";
  const industry = body?.industry ?? "Not provided";
  const tone = body?.tone ?? "Professional";
  const strongRewrite = body?.strong_rewrite === true;
  const template = body?.resumeData?.template;
  const templateGuide = templateToneInstruction(template);
  const temperature = generationTemperature(template, strongRewrite);

  if (!resumeData || typeof resumeData !== "object") {
    return jsonResponse(400, { error: "resumeData is required and must be an object" });
  }

  try {
    if (isGenerate) {
      const jobDescriptionOrNull = body?.job_description_or_null ?? null;

      const userPrompt = `
Transform the following resume data.

User Context:
Career Level: ${careerLevel}
Target Role: ${targetRole}
Industry: ${industry}
Preferred Tone: ${tone}
Template Guide: ${templateGuide}

Optional Job Description:
${jobDescriptionOrNull ?? "null"}

Resume Data:
${JSON.stringify(resumeData)}

Raw Notes (may be noisy/poorly written):
${typeof resumeData?.raw_resume_text === "string" ? resumeData.raw_resume_text : ""}

FORMAT EXPECTATIONS (match premium professional sample style):
- Keep concise single-line contact info (name, role, email, phone, linkedin/github if available).
- Keep summary to 2-4 lines, role-aligned and keyword rich.
- Experience/project bullets must start with strong action verbs and include metrics where possible.
- Keep bullet length around 10-20 words for ATS readability.
- Avoid generic filler and repeated statements.

QUALITY EXPECTATIONS:
- Do not mirror raw wording when it is weak; rewrite into polished business language.
- Normalize grammar, tense, and clarity across all sections.
- Keep facts grounded in input, but improve quality to sample-level professionalism.
- If a field is sparse, produce the best professional version possible without adding unrealistic claims.

REWRITE INTENSITY:
- Strong rewrite mode: ${strongRewrite ? "ON" : "OFF"}
- When ON, aggressively rewrite weak phrasing into sharper professional wording while preserving factual intent.
- When ON, avoid carrying over any awkward sentence structure from raw input.

VARIATION RULES:
- Return three high-quality variants that remain close to this same premium structure.
- Vary only writing tone subtly (concise/formal/assertive), not section quality or output format.
- Do not introduce noisy or low-quality alternatives.

Return ONLY valid JSON in this shape:
{
  "variations": [ <resume_json_1>, <resume_json_2>, <resume_json_3> ]
}
`;

      const messages = [
        { role: "system" as const, content: systemPrompt },
        { role: "user" as const, content: userPrompt },
      ];

      const first = await callGroq(messages, { temperature });
      const parsed = await parseJsonWithRepair(messages, first, { temperature });

      let variations: unknown[] = [];
      if (Array.isArray(parsed)) {
        variations = parsed;
      } else if (parsed && typeof parsed === "object" && Array.isArray((parsed as any).variations)) {
        variations = (parsed as any).variations;
      }

      if (variations.length < 3) {
        return jsonResponse(502, { error: "AI response must include 3 resume variations" });
      }

      return jsonResponse(200, {
        variations: variations.slice(0, 3).map((v) => toJsonString(v)),
      });
    }

    if (isAts) {
      const targetKeywords = Array.isArray(body?.target_keywords)
        ? body.target_keywords.map((x: unknown) => String(x).trim()).filter((x: string) => x.length > 0)
        : [];

      const resumeText = typeof body?.resume_text === "string"
        ? body.resume_text
        : JSON.stringify(resumeData);

      const userPrompt = `
Analyze this resume for ATS quality and return a strict scored inspection.

User Context:
Career Level: ${careerLevel}
Target Role: ${targetRole}
Industry: ${industry}
Preferred Tone: ${tone}
Template Guide: ${templateGuide}

Target Keywords:
${targetKeywords.join(", ") || "none"}

Resume Text:
${resumeText}

Resume Data:
${JSON.stringify(resumeData)}

Return ONLY valid JSON in this shape:
{
  "total_score": 0-100,
  "keyword_score": 0-40,
  "bullet_score": 0-20,
  "length_score": 0-20,
  "readability_score": 0-20,
  "missing_keywords": ["..."],
  "suggestions": ["...", "...", "..."]
}

Rules:
- Be strict but fair.
- Suggestions must be practical and ATS-relevant.
- Do not include markdown or explanations.
`;

      const messages = [
        { role: "system" as const, content: systemPrompt },
        { role: "user" as const, content: userPrompt },
      ];

      const first = await callGroq(messages, { temperature: 0.16 });
      const parsed = await parseJsonWithRepair(messages, first, { temperature: 0.16 });

      if (!parsed || typeof parsed !== "object") {
        return jsonResponse(502, { error: "Invalid ATS response format" });
      }

      const out = parsed as any;
      const toScore = (value: unknown, fallback: number, min: number, max: number) => {
        const numeric = typeof value === "number"
          ? value
          : typeof value === "string"
            ? Number(value)
            : NaN;
        if (Number.isFinite(numeric)) {
          return Math.max(min, Math.min(max, Math.round(numeric)));
        }
        return fallback;
      };

      const missingKeywords = Array.isArray(out.missing_keywords)
        ? out.missing_keywords.map((x: unknown) => String(x)).filter((x: string) => x.trim().length > 0)
        : [];
      const suggestions = Array.isArray(out.suggestions)
        ? out.suggestions.map((x: unknown) => String(x)).filter((x: string) => x.trim().length > 0)
        : [];

      if (suggestions.length === 0) {
        return jsonResponse(502, { error: "ATS response must include suggestions" });
      }

      const keywordScore = toScore(out.keyword_score, 24, 0, 40);
      const bulletScore = toScore(out.bullet_score, 12, 0, 20);
      const lengthScore = toScore(out.length_score, 12, 0, 20);
      const readabilityScore = toScore(out.readability_score, 12, 0, 20);
      const computedTotal = keywordScore + bulletScore + lengthScore + readabilityScore;
      const totalScore = toScore(out.total_score, computedTotal, 0, 100);

      return jsonResponse(200, {
        total_score: totalScore,
        keyword_score: keywordScore,
        bullet_score: bulletScore,
        length_score: lengthScore,
        readability_score: readabilityScore,
        missing_keywords: missingKeywords,
        suggestions,
      });
    }

    const jobDescription = body?.jobDescription;
    if (!jobDescription || typeof jobDescription !== "string") {
      return jsonResponse(400, { error: "jobDescription is required for /resume/optimize" });
    }

    const userPrompt = `
Analyze this resume against the job description and return practical ATS improvement suggestions.

User Context:
Career Level: ${careerLevel}
Target Role: ${targetRole}
Industry: ${industry}
Preferred Tone: ${tone}
Template Guide: ${templateGuide}

Job Description:
${jobDescription}

Resume Data:
${JSON.stringify(resumeData)}

Return ONLY valid JSON in this shape:
{
  "suggestions": ["...", "...", "..."]
}
`;

    const messages = [
      { role: "system" as const, content: systemPrompt },
      { role: "user" as const, content: userPrompt },
    ];

    const first = await callGroq(messages, { temperature: 0.18 });
    const parsed = await parseJsonWithRepair(messages, first, { temperature: 0.18 });

    let suggestions: string[] = [];
    if (Array.isArray(parsed)) {
      suggestions = parsed.map((x) => String(x));
    } else if (parsed && typeof parsed === "object" && Array.isArray((parsed as any).suggestions)) {
      suggestions = (parsed as any).suggestions.map((x: unknown) => String(x));
    }

    if (suggestions.length === 0) {
      return jsonResponse(502, { error: "Invalid optimize response format" });
    }

    return jsonResponse(200, { suggestions });
  } catch (error) {
    return jsonResponse(500, {
      error: "AI function failed",
      details: error instanceof Error ? error.message : String(error),
    });
  }
});