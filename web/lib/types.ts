export interface User {
  id: string;
  name: string;
  email: string;
  role: "admin" | "inspector" | "viewer";
}

export interface Site {
  id: string;
  name: string;
  address: string;
  lat: number | null;
  lng: number | null;
  status: "active" | "completed" | "paused";
  start_date: string | null;
  end_date: string | null;
  manager_id: string | null;
  created_at: string;
}

export interface Inspection {
  id: string;
  site_id: string;
  inspector_id: string;
  category: string;
  status: "pass" | "fail" | "pending";
  memo: string | null;
  location_lat: number | null;
  location_lng: number | null;
  inspected_at: string;
  is_synced: boolean;
  created_at: string;
}

export interface Defect {
  id: string;
  inspection_id: string;
  severity: "critical" | "major" | "minor";
  description: string;
  resolved_at: string | null;
  resolved_by_id: string | null;
  created_at: string;
}

export interface DashboardSummary {
  total_sites: number;
  active_sites: number;
  total_inspections: number;
  pass_rate: number;
  pending_inspections: number;
  total_defects: number;
  unresolved_defects: number;
}

export interface DefectSummary {
  critical: number;
  major: number;
  minor: number;
  total: number;
}

export interface RecentInspection {
  id: string;
  site_name: string;
  inspector_name: string;
  category: string;
  status: string;
  inspected_at: string;
}

export interface UnresolvedDefect {
  id: string;
  site_name: string;
  inspection_id: string;
  severity: string;
  description: string;
  created_at: string;
}

export interface DashboardData {
  summary: DashboardSummary;
  defect_summary: DefectSummary;
  recent_inspections: RecentInspection[];
  unresolved_defects: UnresolvedDefect[];
}

export interface DailyInspectionStat {
  date: string;
  count: number;
  pass_count: number;
}

export interface WeeklyStats {
  daily_inspections: DailyInspectionStat[];
  defect_severity: DefectSummary;
}
