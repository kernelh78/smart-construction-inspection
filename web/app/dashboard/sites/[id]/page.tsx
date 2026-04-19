"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { getSite, getInspections } from "@/lib/api";
import type { Site, Inspection } from "@/lib/types";
import Badge from "@/components/ui/Badge";

export default function SiteDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [site, setSite] = useState<Site | null>(null);
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getSite(id), getInspections(id)])
      .then(([s, i]) => { setSite(s.data); setInspections(i.data); })
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="flex h-64 items-center justify-center text-gray-400">로딩 중...</div>;
  if (!site) return <div className="text-gray-400">현장을 찾을 수 없습니다.</div>;

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-2">
        <Link href="/dashboard/sites" className="text-sm text-gray-400 hover:text-gray-600">← 현장 목록</Link>
      </div>
      <div className="rounded-xl border bg-white p-5">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-800">{site.name}</h1>
            <p className="text-sm text-gray-500 mt-1">{site.address}</p>
          </div>
          <Badge value={site.status} />
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 text-sm text-gray-600">
          <div><span className="font-medium text-gray-700">시작일:</span> {site.start_date ? new Date(site.start_date).toLocaleDateString("ko-KR") : "-"}</div>
          <div><span className="font-medium text-gray-700">종료일:</span> {site.end_date ? new Date(site.end_date).toLocaleDateString("ko-KR") : "-"}</div>
          {site.lat && <div><span className="font-medium text-gray-700">위도:</span> {site.lat}</div>}
          {site.lng && <div><span className="font-medium text-gray-700">경도:</span> {site.lng}</div>}
        </div>
      </div>

      <div className="rounded-xl border bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-gray-600">점검 기록 ({inspections.length}건)</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs text-gray-400">
              <th className="pb-2 font-medium">공종</th>
              <th className="pb-2 font-medium">상태</th>
              <th className="pb-2 font-medium">메모</th>
              <th className="pb-2 font-medium">점검일</th>
              <th className="pb-2 font-medium">상세</th>
            </tr>
          </thead>
          <tbody>
            {inspections.map((insp) => (
              <tr key={insp.id} className="border-b last:border-0">
                <td className="py-2 font-medium text-gray-800">{insp.category}</td>
                <td className="py-2"><Badge value={insp.status} /></td>
                <td className="py-2 text-gray-500 max-w-xs truncate">{insp.memo ?? "-"}</td>
                <td className="py-2 text-gray-400">{new Date(insp.inspected_at).toLocaleDateString("ko-KR")}</td>
                <td className="py-2">
                  <Link href={`/dashboard/inspections/${insp.id}`} className="text-blue-500 hover:underline text-xs">
                    보기 →
                  </Link>
                </td>
              </tr>
            ))}
            {inspections.length === 0 && (
              <tr><td colSpan={5} className="py-4 text-center text-gray-400">점검 기록 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
