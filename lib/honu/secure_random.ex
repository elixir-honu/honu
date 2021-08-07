defmodule Honu.SecureRandom do
  @default_length 16
  @base36_alphabet "0123456789abcdefghijklmnopqrstuvwxyz"

  @doc """
  Returns random Base36 encoded string.

  ## Examples

      iex> Honu.SecureRandom.base36
      "7coz8ju9gue4liebt3481e5tg"

      iex> Honu.SecureRandom.base36(8)
      "kckitp81brv6"

  """
  def base36(n \\ @default_length) do
    # TODO: Maybe use base36 when available:
    # random_bytes(n)
    # |> Base.encode36(case: :lower)

    random_bytes(n)
    |> String.codepoints()
    |> Enum.map(&:binary.decode_unsigned/1)
    |> Enum.map(fn byte ->
      idx = rem(byte, 64)

      if idx >= 36 do
        String.at(@base36_alphabet, Enum.random(0..31))
      else
        String.at(@base36_alphabet, idx)
      end
    end)
    |> Enum.join()
  end

  @doc """
  Returns random Base64 encoded string.

  ## Examples

      iex> Honu.SecureRandom.base64
      "rm/JfqH8Y+Jd7m5SHTHJoA=="

      iex> Honu.SecureRandom.base64(8)
      "2yDtUyQ5Xws="

  """
  def base64(n \\ @default_length) do
    random_bytes(n)
    |> Base.encode64()
  end

  @doc """
  Generates a random hexadecimal string.

  The argument n specifies the length, in bytes, of the random number to be generated. The length of the resulting hexadecimal string is twice n.

  If n is not specified, 16 is assumed. It may be larger in future.

  The result may contain 0-9 and a-f.

  ## Examples

      iex> Honu.SecureRandom.hex(6)
      "34fb5655a231"
  """
  def hex(n \\ @default_length) do
    random_bytes(n)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Returns random bytes.

  ## Examples

      iex> Honu.SecureRandom.random_bytes
      <<202, 104, 227, 197, 25, 7, 132, 73, 92, 186, 242, 13, 170, 115, 135, 7>>

      iex> Honu.SecureRandom.random_bytes(8)
      <<231, 123, 252, 174, 156, 112, 15, 29>>

  """
  def random_bytes(n \\ @default_length) do
    :crypto.strong_rand_bytes(n)
  end
end
