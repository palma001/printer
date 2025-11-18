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
        env = os.getenv("ENV", "dev")
        return env if env in ("dev", "prod") else "dev"
