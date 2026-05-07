import os
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types
from openai import OpenAI

app = Server("kimi-copy")


@app.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="generate_copy",
            description="使用 Kimi AI 生成文案内容",
            inputSchema={
                "type": "object",
                "properties": {
                    "prompt": {
                        "type": "string",
                        "description": "文案生成提示词，描述你想要的内容"
                    }
                },
                "required": ["prompt"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name != "generate_copy":
        return [types.TextContent(type="text", text=f"未知工具: {name}")]

    api_key = os.environ.get("KIMI_API_KEY")
    if not api_key:
        return [types.TextContent(type="text", text="错误: KIMI_API_KEY 环境变量未设置")]

    prompt = arguments.get("prompt", "").strip()
    if not prompt:
        return [types.TextContent(type="text", text="错误: prompt 不能为空")]

    client = OpenAI(
        api_key=api_key,
        base_url="https://api.moonshot.cn/v1"
    )

    response = client.chat.completions.create(
        model="moonshot-v1-8k",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7
    )

    content = response.choices[0].message.content
    return [types.TextContent(type="text", text=content)]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
