import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";

function VerifyEmailPage() {
  const [params] = useSearchParams();
  const [message, setMessage] = useState(
    params.get("token")
      ? "E-posta doğrulanıyor…"
      : "Doğrulama bağlantısı geçersiz.",
  );
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    const token = params.get("token");
    if (!token) return;
    void fetch("/api/auth/verify-email", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
    })
      .then(async (response) => {
        const result = await response.json();
        if (!response.ok)
          throw new Error(result.errors?.join(", ") || "Doğrulama başarısız.");
        setSuccess(true);
        setMessage(result.message);
      })
      .catch((error: unknown) => {
        setMessage(
          error instanceof Error ? error.message : "Doğrulama başarısız.",
        );
      });
  }, [params]);

  return (
    <main className="mx-auto max-w-xl px-5 py-16">
      <h1 className="text-2xl font-semibold">E-posta doğrulama</h1>
      <p role={success ? "status" : "alert"} className="mt-4">
        {message}
      </p>
      {success && (
        <Link
          to="/login"
          className="mt-6 inline-block border border-stone-900 px-5 py-3 text-sm font-semibold"
        >
          Giriş yap
        </Link>
      )}
    </main>
  );
}

export default VerifyEmailPage;
