using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

namespace Read.er.Services;

public class EmbeddingService
{
    private readonly InferenceSession _session;

    public EmbeddingService(string modelPath)
    {
        if (!File.Exists(modelPath))
            throw new FileNotFoundException($"O arquivo do modelo '{modelPath}' não foi encontrado.");

        _session = new InferenceSession(modelPath);
    }

    /// <summary>
    /// Generates an embedding vector from the provided text using a pre-trained model.
    /// </summary>
    /// <param name="text">The input text to be converted into an embedding vector.</param>
    /// <returns>A float array representing the embedding vector of the input text.</returns>
    /// <exception cref="System.IO.FileNotFoundException">Thrown when the specified model file does not exist.</exception>
    /// <exception cref="System.NotImplementedException">Thrown when text preprocessing is not implemented.</exception>
    public float[] GenerateEmbedding(string text)
    {
        try
        {
            // Pré-processamento do texto para criar o tensor de entrada
            var inputTensor = PreprocessText(text);

            var inputs = new[]
            {
                NamedOnnxValue.CreateFromTensor("input_ids", inputTensor) // Certifique-se de que o nome corresponde ao modelo
            };

            // Executa o modelo e obtém o resultado
            using var results = _session.Run(inputs);
            var embedding = results.First().AsEnumerable<float>().ToArray();

            if (embedding.Length == 0)
                throw new Exception("Embedding gerado está vazio.");

            return embedding;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao gerar o embedding: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Preprocesses the input text by tokenizing and converting it into a tensor of input IDs suitable for a model.
    /// </summary>
    /// <param name="text">The input text that needs to be preprocessed into input IDs.</param>
    /// <returns>A DenseTensor of longs representing the tokenized and indexed input text.</returns>
    /// <exception cref="System.NotImplementedException">Thrown when the method for text preprocessing is not yet implemented.</exception>
    private DenseTensor<long> PreprocessText(string text)
    {
        // Exemplo básico de tokenização e indexação. Substitua por lógica adequada ao modelo.
        var tokens = TokenizeText(text);
        var maxLength = 128; // Ajuste conforme necessário
        var inputIds = tokens.Take(maxLength).Concat(Enumerable.Repeat(0L, maxLength - tokens.Count)).ToArray(); // Padding

        return new DenseTensor<long>(inputIds, new[] { 1, maxLength }); // Batch de tamanho 1
    }

    private List<long> TokenizeText(string text)
    {
        // Simulação de tokenização: converte caracteres em valores ASCII como exemplo.
        // Substitua por uma lógica real, como usar vocabulário pré-treinado do modelo.
        return text
            .Select(c => (long)c % 256) // Exemplo simples de indexação
            .ToList();
    }

    /// <summary>
    /// Calculates the cosine similarity between two embedding vectors.
    /// </summary>
    /// <param name="embedding1">The first embedding vector.</param>
    /// <param name="embedding2">The second embedding vector.</param>
    /// <returns>A float representing the cosine similarity between the two vectors.</returns>
    public float CalculateCosineSimilarity(float[] embedding1, float[] embedding2)
    {
        if (embedding1.Length != embedding2.Length)
            throw new ArgumentException("Os vetores de embedding devem ter o mesmo tamanho.");

        var dotProduct = 0.0f;
        var magnitudeA = 0.0f;
        var magnitudeB = 0.0f;

        for (var i = 0; i < embedding1.Length; i++)
        {
            dotProduct += embedding1[i] * embedding2[i];
            magnitudeA += embedding1[i] * embedding1[i];
            magnitudeB += embedding2[i] * embedding2[i];
        }

        return dotProduct / (float)(Math.Sqrt(magnitudeA) * Math.Sqrt(magnitudeB));
    }
}
