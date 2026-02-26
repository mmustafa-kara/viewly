# 🎬 Viewly - Movie & TV Show Social Network

<div align="center">
  <img src="assets/logo.png" width="150" alt="Viewly Logo">
</div>

<br>

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white" alt="Firebase">
  <img src="https://img.shields.io/badge/Riverpod-000000?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod">
  <img src="https://img.shields.io/badge/TMDb_API-01B4E4?style=for-the-badge&logo=themoviedb&logoColor=white" alt="TMDb">
</div>

**Viewly**, sinema ve dizi tutkunlarını bir araya getiren, modern mimariyle geliştirilmiş tam teşekküllü bir mobil sosyal ağ uygulamasıdır. Kullanıcılar yeni yapımlar keşfedebilir, arkadaş ekleyebilir ve izledikleri içerikler hakkında tartışma başlatabilirler.

---

## 📸 Ekran Görüntüleri

> **Not:** Uygulamanın GitHub'daki görünümünü zenginleştirmek için aşağıdaki placeholder (yer tutucu) resim linklerini kendi aldığın ekran görüntüsü linkleriyle değiştir. (Resimleri GitHub'da bir issue'ya sürükleyip bırakarak linklerini alabilirsin).

<p align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Ana+Ekran" width="22%">
  <img src="https://via.placeholder.com/250x500.png?text=Film+Detayi" width="22%">
  <img src="https://via.placeholder.com/250x500.png?text=Tartismalar" width="22%">
  <img src="https://via.placeholder.com/250x500.png?text=Kullanici+Profili" width="22%">
</p>

---

## 🏗️ Sistem Mimarisi ve Veri Akışı

Viewly, kodun sürdürülebilirliği ve test edilebilirliği için **MVVM (Model-View-ViewModel)** ve **Clean Architecture** prensiplerine sıkı sıkıya bağlı kalınarak tasarlanmıştır.



* **View (Arayüz):** Sadece kullanıcı arayüzünü çizer. İş mantığı barındırmaz.
* **ViewModel (Durum Yönetimi):** Riverpod kullanılarak `View` ile `Services` arasındaki köprüyü kurar.
* **Data/Services (Veri Katmanı):** Firebase ve TMDb API ile asenkron iletişimi sağlar.

---

## ✨ Öne Çıkan Özellikler

* **🔐 Kimlik Doğrulama:** Firebase Auth ile güvenli giriş, kayıt ve şifre sıfırlama.
* **📡 Dinamik Keşif:** TMDb API entegrasyonu ile anlık güncellenen trend filmler, diziler ve sonsuz kaydırma (Pagination).
* **👥 Arkadaşlık Sistemi:** Çift yönlü arkadaş ekleme, istek onaylama/reddetme ve arama motoru.
* **💬 Sosyal Etkileşim:** Konu (Thread) açma, beğenme ve yorum yapma özelliklerine sahip interaktif ağ.
* **🗂️ CRUD İşlemleri:** Kullanıcıların kendi gönderilerini silebilmesi ve hesabı kalıcı olarak yok etme (KVKK Uyumu).

---

## 🚀 Kurulum ve Çalıştırma

Bu projeyi kendi ortamınızda test etmek için aşağıdaki adımları izleyin:

### 1. Repoyu Klonlayın
```bash
git clone [https://github.com/mmustafa-kara/viewly.git](https://github.com/mmustafa-kara/viewly.git)
cd viewly
