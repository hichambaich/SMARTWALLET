import http.server
import socketserver

PORT = 8080
Handler = http.server.SimpleHTTPRequestHandler

# استخدام ThreadingTCPServer يسمح بتحميل عدة ملفات في نفس الوقت
# ويمنع خطأ ConnectionResetError
class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

with ThreadingHTTPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"✅ الخادم يعمل الآن على المنفذ {PORT}")
    httpd.serve_forever()
