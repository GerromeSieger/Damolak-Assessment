import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Damolak Web App",
  description: "Production-ready Next.js application on AWS ECS Fargate",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
