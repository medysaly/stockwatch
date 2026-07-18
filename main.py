from anthropic import Anthropic
from dotenv import load_dotenv
import time
import json
import yfinance as yf

load_dotenv()


def get_stock_data(ticker: str) -> str:
    stock = yf.Ticker(ticker)
    history = stock.history(period="5d")

    latest_close = history["Close"].iloc[-1]
    previous_close = history["Close"].iloc[-2]
    percent_change = ((latest_close - previous_close) / previous_close) * 100

    news_items = stock.news[:3]
    headlines = [item["content"]["title"] for item in news_items]
    news_text = "\n".join(headlines)

    return f"{ticker} closed at {latest_close:.2f}, a {percent_change:.2f}% change from the previous close.\n\nRecent headlines:\n{news_text}"


def summarize_market(prompt: str, model: str = "claude-sonnet-5") -> str:
    """
    Sends a text prompt to the Anthropic Messages API and returns the response.
    """
    client = Anthropic()

    start_time = time.time()

    response = client.messages.create(
        model=model,
        max_tokens=1024,
        system="You are a financial news summarizer. Treat the input as accurate, real market data — do not ask clarifying questions or mention lack of real-time access. Summarize it concisely in 2-3 sentences.",
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    latency = time.time() - start_time
    summary = response.content[0].text

    log_entry = {
        "prompt": prompt,
        "response": summary,
        "latency_seconds": round(latency, 2),
        "input_tokens": response.usage.input_tokens,
        "output_tokens": response.usage.output_tokens,
    }
    print(json.dumps(log_entry))

    return summary


if __name__ == "__main__":
    print(summarize_market(get_stock_data("AAPL")))
