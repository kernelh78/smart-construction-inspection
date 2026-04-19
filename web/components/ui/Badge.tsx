const variants: Record<string, string> = {
  pass: "bg-green-100 text-green-700",
  fail: "bg-red-100 text-red-700",
  pending: "bg-yellow-100 text-yellow-700",
  active: "bg-blue-100 text-blue-700",
  completed: "bg-gray-100 text-gray-600",
  paused: "bg-orange-100 text-orange-700",
  critical: "bg-red-100 text-red-700",
  major: "bg-orange-100 text-orange-700",
  minor: "bg-yellow-100 text-yellow-700",
};

const labels: Record<string, string> = {
  pass: "합격", fail: "불합격", pending: "대기",
  active: "진행중", completed: "완료", paused: "중단",
  critical: "심각", major: "중요", minor: "경미",
};

export default function Badge({ value }: { value: string }) {
  const cls = variants[value] ?? "bg-gray-100 text-gray-600";
  return (
    <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${cls}`}>
      {labels[value] ?? value}
    </span>
  );
}
