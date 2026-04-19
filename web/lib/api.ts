import axios from "axios";
import Cookies from "js-cookie";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

const api = axios.create({ baseURL: BASE_URL });

api.interceptors.request.use((config) => {
  const token = Cookies.get("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && typeof window !== "undefined") {
      Cookies.remove("token");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

// Auth
export const login = (email: string, password: string) => {
  const form = new URLSearchParams();
  form.append("username", email);
  form.append("password", password);
  return api.post<{ access_token: string; token_type: string }>(
    "/api/v1/auth/login",
    form,
    { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
  );
};
export const logout = () => api.post("/api/v1/auth/logout");
export const getMe = () => api.get("/api/v1/auth/me");

// Dashboard
export const getDashboard = () => api.get("/api/v1/dashboard/");
export const getWeeklyStats = () => api.get("/api/v1/dashboard/weekly-stats");

// Sites
export const getSites = () => api.get("/api/v1/sites/");
export const getSite = (id: string) => api.get(`/api/v1/sites/${id}`);
export const createSite = (data: object) => api.post("/api/v1/sites/", data);
export const updateSite = (id: string, data: object) => api.put(`/api/v1/sites/${id}`, data);
export const deleteSite = (id: string) => api.delete(`/api/v1/sites/${id}`);

// Inspections
export const getInspections = (siteId?: string) =>
  api.get("/api/v1/inspections/", { params: siteId ? { site_id: siteId } : {} });
export const getInspection = (id: string) => api.get(`/api/v1/inspections/${id}`);
export const createDefect = (inspectionId: string, data: object) =>
  api.post(`/api/v1/inspections/${inspectionId}/defects`, data);

export default api;
