export default function Home() {
  const apiBaseUrl = process.env.API_BASE_URL ?? "not configured";
  const nodeEnv = process.env.NODE_ENV ?? "unknown";
  const region = process.env.AWS_REGION ?? "unknown";

  return (
    <main className="container">
      <span className="badge">Running</span>
      <h1>Damolak Web App</h1>
      <p className="subtitle">
        Deployed on AWS ECS Fargate &middot; Next.js 15
      </p>

      <div className="info-card">
        <div className="info-row">
          <span className="info-label">Environment</span>
          <span className="info-value">{nodeEnv}</span>
        </div>
        <div className="info-row">
          <span className="info-label">AWS Region</span>
          <span className="info-value">{region}</span>
        </div>
        <div className="info-row">
          <span className="info-label">API Base URL</span>
          <span className="info-value">{apiBaseUrl}</span>
        </div>
        <div className="info-row">
          <span className="info-label">Health Check</span>
          <span className="info-value">/api/health</span>
        </div>
      </div>
    </main>
  );
}
