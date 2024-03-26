from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return 'Bienvenido al home page!'

@app.route('/test')
def test():
    return 'Este es el endpoint /test'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
