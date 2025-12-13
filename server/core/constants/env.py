import os
from typing import Literal


class EnvVariables:
    @classmethod
    def host(cls) -> str:
        return os.getenv("API_HOST", "localhost")

    @classmethod
    def port(cls) -> int:
        return int(os.getenv("API_PORT", "8000"))

    @classmethod
    def environment(cls) -> Literal["dev", "prod"]:
        env = os.getenv("ENV", "prod")
        return env if env in ("dev", "prod") else "dev"

    @classmethod
    def api_url(cls) -> str:
        return os.getenv(
            "API_URL", "https://api-orderwise.qbitsinc.com/api/public/register-device"
        )

    @classmethod
    def pusher_app_key(cls) -> str:
        return os.getenv("PUSHER_APP_KEY", "baa549b06e82421f4895")

    @classmethod
    def pusher_cluster(cls) -> str:
        return os.getenv("PUSHER_CLUSTER", "us2")

    @classmethod
    def channel(cls) -> str:
        return os.getenv("CHANNEL", "comandas")

    @classmethod
    def event_name(cls) -> str:
        return os.getenv("EVENT_NAME", "NewOrderComanda")

    @classmethod
    def receipt_font_name(cls) -> str:
        return os.getenv("RECEIPT_FONT_NAME", "Consolas")

    @classmethod
    def receipt_font_size(cls) -> int:
        return int(os.getenv("RECEIPT_FONT_SIZE", "8"))

    @classmethod
    def receipt_ticket_paper_size(cls) -> int:
        return int(os.getenv("RECEIPT_TICKET_PAPER_SIZE", "32"))

    @classmethod
    def receipt_comanda_paper_size(cls) -> int:
        return int(os.getenv("RECEIPT_COMANDA_PAPER_SIZE", "54"))
