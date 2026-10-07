import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import Footer from "./components/Footer";
import Header from "./components/Header";
import Navigation from "./components/Navigation";
import AboutPage from "./pages/AboutPage";
import ContactPage from "./pages/ContactPage";
import FaqPage from "./pages/FaqPage";
import HomePage from "./pages/HomePage";
import NotFoundPage from "./pages/NotFoundPage";
import PrivacyPage from "./pages/PrivacyPage";
import ProductsPage from "./pages/ProductsPage";
import ShippingReturnsPage from "./pages/ShippingReturnsPage";
import TermsPage from "./pages/TermsPage";

function App() {
  return (
    <Router>
      <div className="flex min-h-screen flex-col bg-[#f5f8f3] text-emerald-950">
        <Header />
        <Navigation />
        <div className="flex-1">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/urunler" element={<ProductsPage />} />
            <Route path="/hakkimizda" element={<AboutPage />} />
            <Route path="/iletisim" element={<ContactPage />} />
            <Route path="/sss" element={<FaqPage />} />
            <Route path="/teslimat-iade" element={<ShippingReturnsPage />} />
            <Route path="/gizlilik" element={<PrivacyPage />} />
            <Route path="/kullanim-kosullari" element={<TermsPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Routes>
        </div>
        <Footer />
      </div>
    </Router>
  );
}

export default App;
