import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

type AdminUser = {
  id: number;
  name: string;
  email: string;
  role: "user" | "admin";
  created_at: string;
};

function AdminUsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [message, setMessage] = useState("Kullanıcılar yükleniyor…");
  const navigate = useNavigate();

  useEffect(() => {
    let active = true;
    void fetch("/api/admin/users", { credentials: "same-origin" })
      .then(async (response) => {
        const result = await response.json();
        if (response.status === 401) {
          navigate("/login?returnTo=%2Fadmin%2Fusers");
          return [] as AdminUser[];
        }
        if (!response.ok)
          throw new Error(
            result.errors?.join(", ") || "Kullanıcılar yüklenemedi.",
          );
        if (active) {
          setUsers(result as AdminUser[]);
          setMessage("");
        }
        return result as AdminUser[];
      })
      .catch((error: unknown) => {
        if (active)
          setMessage(
            error instanceof Error
              ? error.message
              : "Kullanıcılar yüklenemedi.",
          );
      });
    return () => {
      active = false;
    };
  }, [navigate]);

  const deleteUser = async (userId: number) => {
    const response = await fetch(`/api/admin/users/${userId}`, {
      method: "DELETE",
      credentials: "same-origin",
    });
    if (response.status === 401) {
      navigate("/login?returnTo=%2Fadmin%2Fusers");
      return;
    }
    if (!response.ok) {
      const result = await response.json();
      setMessage(result.errors?.join(", ") || "Kullanıcı silinemedi.");
      return;
    }
    setUsers((current) => current.filter((user) => user.id !== userId));
  };

  return (
    <main className="mx-auto w-full max-w-5xl px-5 py-10">
      <h1 className="text-2xl font-semibold">Kullanıcı yönetimi</h1>
      {message && (
        <p role="status" className="mt-4 text-sm text-stone-600">
          {message}
        </p>
      )}
      <div className="mt-6 divide-y divide-stone-200 border-y border-stone-200">
        {users.map((user) => (
          <div
            key={user.id}
            className="flex items-center justify-between gap-4 py-4"
          >
            <div>
              <p className="font-medium">
                {user.name}{" "}
                <span className="ml-2 text-xs uppercase text-stone-500">
                  {user.role}
                </span>
              </p>
              <p className="text-sm text-stone-600">{user.email}</p>
            </div>
            <button
              type="button"
              onClick={() => void deleteUser(user.id)}
              className="border border-red-700 px-3 py-2 text-sm text-red-700"
            >
              Sil
            </button>
          </div>
        ))}
      </div>
    </main>
  );
}

export default AdminUsersPage;
