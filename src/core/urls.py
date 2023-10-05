"""
URL configuration for project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path
from django.conf.urls.static import static
from django.conf import settings

urlpatterns = [
  path('accounts/', include('django.contrib.auth.urls'), name="accounts"),
  path('admin/', admin.site.urls, name="admin"),
  path("__reload__/", include("django_browser_reload.urls"), name="reload"),
  path("auth/", include("shauth.urls"), name="shauth"),
  path('', include("apps.main.urls"), name="main"),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

handler400 = "core.views.handler400"
handler403 = "core.views.handler403"
handler404 = "core.views.handler404"
handler500 = "core.views.handler500"
