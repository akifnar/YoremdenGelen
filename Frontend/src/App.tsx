import { useLayoutEffect } from "react";
import {
  BrowserRouter as Router,
  Route,
  Routes,
  Navigate,
  useLocation,
} from "react-router-dom";
import Footer from "./components/Footer";
import GuestCallout from "./components/GuestCallout";
import Header from "./components/Header";

import AboutPage from "./pages/AboutPage";

import CartPage from "./pages/CartPage";
import FaqPage from "./pages/FaqPage";
import HomePage from "./pages/HomePage";
import NotFoundPage from "./pages/NotFoundPage";
import PrivacyPage from "./pages/PrivacyPage";
import ProductDetailPage from "./pages/ProductDetailPage";

import ShippingReturnsPage from "./pages/ShippingReturnsPage";
import TermsPage from "./pages/TermsPage";
import AuthPage from "./pages/AuthPage";
import VerifyEmailPage from "./pages/VerifyEmailPage";
import AdminUsersPage from "./pages/AdminUsersPage";
import SellerProductsPage from "./pages/SellerProductsPage";

function RouteScrollReset() {
  const { pathname } = useLocation();

  useLayoutEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "instant" });
  }, [pathname]);

  return null;
}

function AppRoutes() {
  return (
    <div>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/login" element={<AuthPage mode="login" />} />
        <Route path="/register" element={<AuthPage mode="register" />} />
        <Route path="/verify-email" element={<VerifyEmailPage />} />
        <Route path="/admin/users" element={<AdminUsersPage />} />
        <Route path="/satici/urunler" element={<SellerProductsPage />} />
        <Route path="/urunler" element={<Navigate to="/" replace />} />
        <Route path="/urunler/:slug" element={<ProductDetailPage />} />
        <Route path="/sepet" element={<CartPage />} />
        <Route path="/hakkimizda" element={<AboutPage />} />

        <Route path="/sss" element={<FaqPage />} />
        <Route path="/teslimat-iade" element={<ShippingReturnsPage />} />
        <Route path="/gizlilik" element={<PrivacyPage />} />
        <Route path="/kullanim-kosullari" element={<TermsPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </div>
  );
}

function App() {
  return (
    <Router>
      <RouteScrollReset />
      <div className="app-shell flex min-h-screen flex-col bg-[var(--page)] text-[var(--ink)]">
        <Header />
        <div className="flex-1">
          <AppRoutes />
        </div>
        <Footer />
        <GuestCallout />
      </div>
    </Router>
  );
}

export default App;
