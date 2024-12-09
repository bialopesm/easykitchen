class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all

  end

  def new
    @recipe = Recipe.new # Needed to instantiate the form_with
  end

  def create
    @recipe = Recipe.new(recipe_params)
    @recipe.save
    # No need for app/views/recipes/create.html.erb
    redirect_to recipe_path(@recipe)
  end

  def edit
    @recipe = Recipe.find(params[:id])
  end

  def update
    @recipe = Recipe.find(params[:id])
    @recipe.update(recipe_params)
    # No need for app/views/recipes/update.html.erb
    redirect_to recipe_path(@recipe)
  end

  def show
    client = OpenAI::Client.new
    chatgpt_response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [{
        role: "user",
        content: "Create a recipe using the following ingredients:

          The ingredients are: chicken/cheese/tomato.

          The recipe should include and return exactly this format:
          - Recipe title:
          - Ingredients list: (exactly as given all the ingredients)
          - Preparation time:
          - Servings:
          - Step-by-step: (instructions with details for each step)"
      }]
    })

    Rails.logger.info "ChatGPT Response: #{chatgpt_response.inspect}"

    response_content = chatgpt_response["choices"][0]["message"]["content"]

    Rails.logger.info "Response Content: #{response_content}"

    @recipe = {
      "Recipe title" => extract_value(response_content, "Recipe title:"),
      "Ingredients list" => extract_ingredients(response_content, "Ingredients list:"),
      "Preparation time" => extract_value(response_content, "Preparation time:"),
      "Servings" => extract_value(response_content, "Servings:"),
      "Step-by-step" => extract_steps(response_content, "Step-by-step:")
    }

    Rails.logger.info "Structured Recipe: #{@recipe.inspect}"
  end

  private

  def extract_value(content, key)
    match = content.match(/#{key}\s*(.*?)(?=\n\s*-|\z)/)
    match ? match[1].strip : nil
  end

  def extract_ingredients(content, key)
    match = content.match(/#{key}\s*(.*?)(?=\n\s*-|\z)/)
    if match
      ingredients = match[1].strip
      ingredients.split("\n").map { |ingredient| ingredient.gsub(/^- /, '').strip }.join(", ")
    else
      nil
    end
  end

  def extract_steps(content, key)
    match = content.match(/#{key}\s*(.*?)(?=\z)/m)
    match ? match[1].strip : nil
  end

  def recipe_params
    params.require(:recipe).permit(:title, :rating, :instructions, :prep_time, :done, :servings)
  end
end
