from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

def summarize_market(prompt: str, model: str = "claude-sonnet-5") -> str:
    """
    Sends a text prompt to the Anthropic Messages API and returns the response.
    """
    client = Anthropic()

    response = client.messages.create(
        model=model,
        max_tokens=1024,
        system="You are a financial news summarizer. Treat the input as accurate, real market data — do not ask clarifying questions or mention lack of real-time access. Summarize it concisely in 2-3 sentences.",
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return response.content[0].text

if __name__ == "__main__":
    print(summarize_market("Apple stock rose 3% today after strong iPhone sales."))
