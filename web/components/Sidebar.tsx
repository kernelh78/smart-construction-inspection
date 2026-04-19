"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import Cookies from "js-cookie";
import { logout } from "@/lib/api";

const navItems = [
  { href: "/dashboard", label: "대시보드", icon: "📊" },
  { href: "/dashboard/sites", label: "현장 관리", icon: "🏗️" },
  { href: "/dashboard/inspections", label: "점검 기록", icon: "📋" },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = async () => {
    try { await logout(); } catch {}
    Cookies.remove("token");
    router.push("/login");
  };

  return (
    <aside className="flex h-screen w-56 flex-col bg-gray-900 text-white">
      <div className="px-6 py-5 text-lg font-bold tracking-tight border-b border-gray-700">
        🔍 SmartDB
      </div>
      <nav className="flex-1 overflow-y-auto py-4 space-y-1 px-3">
        {navItems.map((item) => {
          const active =
            item.href === "/dashboard"
              ? pathname === "/dashboard"
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors ${
                active
                  ? "bg-blue-600 text-white"
                  : "text-gray-300 hover:bg-gray-800 hover:text-white"
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t border-gray-700 p-4">
        <button
          onClick={handleLogout}
          className="w-full rounded-lg px-3 py-2 text-sm text-gray-300 hover:bg-gray-800 hover:text-white text-left transition-colors"
        >
          🚪 로그아웃
        </button>
      </div>
    </aside>
  );
}
