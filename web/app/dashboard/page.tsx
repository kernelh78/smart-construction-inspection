"use client";

import { useEffect, useState } from "react";
import { getDashboard, getWeeklyStats } from "@/lib/api";
import type { DashboardData, WeeklyStats } from "@/lib/types";
import StatCard from "@/components/ui/StatCard";
import Badge from "@/components/ui/Badge";
import WeeklyBarChart from "@/components/charts/WeeklyBarChart";
import DefectPieChart from "@/components/charts/DefectPieChart";

export default function DashboardPage() {
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [weekly, setWeekly] = useState<WeeklyStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getDashboard(), getWeeklyStats()])
      .then(([d, w]) => {
        setDashboard(d.data);
        setWeekly(w.data);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex h-64 items-center justify-center text-gray-400">로딩 중...</div>;
  if (!dashboard || !weekly) return null;

  const { summary, defect_summary, recent_inspections, unresolved_defects } = dashboard;

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-800">대시보드</h1>

      {/* 요약 카드 */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard title="전체 현장" value={summary.total_sites} sub={`진행중 ${summary.active_sites}`} color="blue" />
        <StatCard title="전체 점검" value={summary.total_inspections} sub={`합격률 ${summary.pass_rate}%`} color="green" />
        <StatCard title="대기 점검" value={summary.pending_inspections} color="yellow" />
        <StatCard title="미결 결함" value={summary.unresolved_defects} sub={`전체 ${summary.total_defects}`} color="red" />
      </div>

      {/* 차트 */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-xl border bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-600">주간 점검 현황</h2>
          <WeeklyBarChart data={weekly.daily_inspections} />
        </div>
        <div className="rounded-xl border bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-600">결함 심각도 분포</h2>
          <DefectPieChart data={weekly.defect_severity} />
        </div>
      </div>

      {/* 최근 점검 */}
      <div className="rounded-xl border bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-gray-600">최근 점검 기록</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs text-gray-400">
              <th className="pb-2 font-medium">현장</th>
              <th className="pb-2 font-medium">감리원</th>
              <th className="pb-2 font-medium">공종</th>
              <th className="pb-2 font-medium">상태</th>
              <th className="pb-2 font-medium">일시</th>
            </tr>
          </thead>
          <tbody>
            {recent_inspections.map((r) => (
              <tr key={r.id} className="border-b last:border-0">
                <td className="py-2 font-medium text-gray-800">{r.site_name}</td>
                <td className="py-2 text-gray-600">{r.inspector_name}</td>
                <td className="py-2 text-gray-600">{r.category}</td>
                <td className="py-2"><Badge value={r.status} /></td>
                <td className="py-2 text-gray-400">{new Date(r.inspected_at).toLocaleString("ko-KR")}</td>
              </tr>
            ))}
            {recent_inspections.length === 0 && (
              <tr><td colSpan={5} className="py-4 text-center text-gray-400">점검 기록 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* 미결 결함 */}
      <div className="rounded-xl border bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-gray-600">미결 결함 현황</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs text-gray-400">
              <th className="pb-2 font-medium">현장</th>
              <th className="pb-2 font-medium">심각도</th>
              <th className="pb-2 font-medium">내용</th>
              <th className="pb-2 font-medium">등록일</th>
            </tr>
          </thead>
          <tbody>
            {unresolved_defects.map((d) => (
              <tr key={d.id} className="border-b last:border-0">
                <td className="py-2 font-medium text-gray-800">{d.site_name}</td>
                <td className="py-2"><Badge value={d.severity} /></td>
                <td className="py-2 text-gray-600">{d.description}</td>
                <td className="py-2 text-gray-400">{new Date(d.created_at).toLocaleDateString("ko-KR")}</td>
              </tr>
            ))}
            {unresolved_defects.length === 0 && (
              <tr><td colSpan={4} className="py-4 text-center text-gray-400">미결 결함 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
