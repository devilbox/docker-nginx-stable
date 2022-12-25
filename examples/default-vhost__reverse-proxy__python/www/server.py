from aiohttp import web

async def handle(request):
    response = '[OK]\nHello from Python\n'
    return web.Response(text=response)

app = web.Application()
app.router.add_get('/', handle)
app.router.add_get('/{name}', handle)

web.run_app(app, port=3000)
