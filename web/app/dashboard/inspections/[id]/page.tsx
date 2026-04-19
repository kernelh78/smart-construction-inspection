"use client";

import { useEffect, useRef, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { getInspection } from "@/lib/api";
import type { Inspection, Defect } from "@/lib/types";
import Badge from "@/components/ui/Badge";
import Cookies from "js-cookie";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

export default function InspectionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [inspection, setInspection] = useState<Inspection | null>(null);
  const [defects, setDefects] = useState<Defect[]>([]);
  const [liveDefects, setLiveDefects] = useState<{ severity: string; description: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    getInspection(id)
      .then((r) => {
        setInspection(r.data);
        // 결함 목록은 별도 엔드포인트가 없어 defects 필드로 대체 (추후 확장)
      })
      .finally(() => setLoading(false));
  }, [id]);

  // WebSocket 실시간 알림 (현장 ID 기반)
  useEffect(() => {
    if (!inspection?.site_id) return;
    const token = Cookies.get("token");
    const ws = new WebSocket(`${BASE_URL.replace(/^http/, "ws")}/ws/sites/${inspection.site_id}/live?token=${token}`);
    ws.onmessage = (e) => {
      try {
        const msg = JSON.parse(e.data);
        if (msg.type === "defect_created" && msg.inspection_id === id) {
          setLiveDefects((prev) => [{ severity: msg.severity, description: msg.description }, ...prev]);
        }
      } catch {}
    };
    wsRef.current = ws;
    return () => ws.close();
  }, [inspection?.site_id, id]);

  if (loading) return <div className="flex h-64 items-center justify-center text-gray-400">로딩 중...</div>;
  if (!inspection) return <div className="text-gray-400">점검 기록을 찾을 수 없습니다.</div>;

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-2">
        <Link href="/dashboard/inspections" className="text-sm text-gray-400 hover:text-gray-600">← 점검 목록</Link>
      </div>

      <div className="rounded-xl border bg-white p-5">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-800">{inspection.category} 점검</h1>
            <p className="text-xs text-gray-400 mt-1">ID: {inspection.id}</p>
          </div>
          <Badge value={inspection.status} />
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 text-sm text-gray-600">
          <div><span className="font-medium text-gray-700">점검일:</span> {new Date(inspection.inspected_at).toLocaleString("ko-KR")}</div>
          <div><span className="font-medium text-gray-700">동기화:</span> {inspection.is_synced ? "완료" : "미완료"}</div>
          {inspection.memo && <div className="col-span-2"><span className="font-medium text-gray-700">메모:</span> {inspection.memo}</div>}
        </div>
      </div>

      {/* 실시간 WebSocket 알림 결함 */}
      {liveDefects.length > 0 && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-5">
          <h2 className="mb-3 text-sm font-semibold text-red-600">🔴 실시간 결함 알림</h2>
          <ul className="space-y-2">
            {liveDefects.map((d, i) => (
              <li key={i} className="flex items-center gap-2 text-sm">
                <Badge value={d.severity} />
                <span className="text-gray-700">{d.description}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {defects.length > 0 && (
        <div className="rounded-xl border bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-600">결함 목록</h2>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-xs text-gray-400">
                <th className="pb-2 font-medium">심각도</th>
                <th className="pb-2 font-medium">내용</th>
                <th className="pb-2 font-medium">처리상태</th>
                <th className="pb-2 font-medium">등록일</th>
              </tr>
            </thead>
            <tbody>
              {defects.map((d) => (
                <tr key={d.id} className="border-b last:border-0">
                  <td className="py-2"><Badge value={d.severity} /></td>
                  <td className="py-2 text-gray-700">{d.description}</td>
                  <td className="py-2"><Badge value={d.resolved_at ? "completed" : "pending"} /></td>
                  <td className="py-2 text-gray-400">{new Date(d.created_at).toLocaleDateString("ko-KR")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
