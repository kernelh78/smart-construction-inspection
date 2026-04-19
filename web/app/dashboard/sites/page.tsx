"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getSites } from "@/lib/api";
import type { Site } from "@/lib/types";
import Badge from "@/components/ui/Badge";

export default function SitesPage() {
  const [sites, setSites] = useState<Site[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getSites().then((r) => setSites(r.data)).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex h-64 items-center justify-center text-gray-400">로딩 중...</div>;

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">현장 관리</h1>
      <div className="rounded-xl border bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr className="text-left text-xs text-gray-400">
              <th className="px-4 py-3 font-medium">현장명</th>
              <th className="px-4 py-3 font-medium">주소</th>
              <th className="px-4 py-3 font-medium">상태</th>
              <th className="px-4 py-3 font-medium">시작일</th>
              <th className="px-4 py-3 font-medium">상세</th>
            </tr>
          </thead>
          <tbody>
            {sites.map((site) => (
              <tr key={site.id} className="border-t hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-medium text-gray-800">{site.name}</td>
                <td className="px-4 py-3 text-gray-600">{site.address}</td>
                <td className="px-4 py-3"><Badge value={site.status} /></td>
                <td className="px-4 py-3 text-gray-400">
                  {site.start_date ? new Date(site.start_date).toLocaleDateString("ko-KR") : "-"}
                </td>
                <td className="px-4 py-3">
                  <Link href={`/dashboard/sites/${site.id}`} className="text-blue-500 hover:underline text-xs">
                    보기 →
                  </Link>
                </td>
              </tr>
            ))}
            {sites.length === 0 && (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-400">현장 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
