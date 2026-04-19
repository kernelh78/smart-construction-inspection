"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getInspections } from "@/lib/api";
import type { Inspection } from "@/lib/types";
import Badge from "@/components/ui/Badge";

export default function InspectionsPage() {
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getInspections().then((r) => setInspections(r.data)).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex h-64 items-center justify-center text-gray-400">로딩 중...</div>;

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">점검 기록</h1>
      <div className="rounded-xl border bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr className="text-left text-xs text-gray-400">
              <th className="px-4 py-3 font-medium">공종</th>
              <th className="px-4 py-3 font-medium">상태</th>
              <th className="px-4 py-3 font-medium">메모</th>
              <th className="px-4 py-3 font-medium">점검일</th>
              <th className="px-4 py-3 font-medium">상세</th>
            </tr>
          </thead>
          <tbody>
            {inspections.map((insp) => (
              <tr key={insp.id} className="border-t hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-medium text-gray-800">{insp.category}</td>
                <td className="px-4 py-3"><Badge value={insp.status} /></td>
                <td className="px-4 py-3 text-gray-500 max-w-xs truncate">{insp.memo ?? "-"}</td>
                <td className="px-4 py-3 text-gray-400">{new Date(insp.inspected_at).toLocaleDateString("ko-KR")}</td>
                <td className="px-4 py-3">
                  <Link href={`/dashboard/inspections/${insp.id}`} className="text-blue-500 hover:underline text-xs">
                    보기 →
                  </Link>
                </td>
              </tr>
            ))}
            {inspections.length === 0 && (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-400">점검 기록 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
