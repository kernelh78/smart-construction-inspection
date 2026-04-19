"use client";

import { PieChart, Pie, Cell, Legend, Tooltip, ResponsiveContainer } from "recharts";
import type { DefectSummary } from "@/lib/types";

const COLORS = ["#ef4444", "#f97316", "#facc15"];

export default function DefectPieChart({ data }: { data: DefectSummary }) {
  const chartData = [
    { name: "심각", value: data.critical },
    { name: "중요", value: data.major },
    { name: "경미", value: data.minor },
  ].filter((d) => d.value > 0);

  if (chartData.length === 0) {
    return (
      <div className="flex h-[260px] items-center justify-center text-gray-400 text-sm">
        미결 결함 없음
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie data={chartData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} label>
          {chartData.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
