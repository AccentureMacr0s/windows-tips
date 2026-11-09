require 'minitest/autorun'
require_relative 'generate_request_gif'

class GenerateRequestGifTest < Minitest::Test
  def test_svg_escapes_request_and_caption
    svg = RequestGif.svg_frame(
      request: '<script>alert("x")</script>',
      caption: 'Bright & sunny',
      frame: 0
    )

    refute_includes svg, '<script>'
    assert_includes svg, '&lt;script&gt;'
    assert_includes svg, 'Bright &amp; sunny'
  end

  def test_svg_includes_sunflower_and_animated_terminal_commands
    first = RequestGif.svg_frame(request: 'sunflower', caption: 'Sunflower', frame: 0)
    later = RequestGif.svg_frame(request: 'sunflower', caption: 'Sunflower', frame: 1)

    assert_includes first, 'chef-client converge'
    assert_includes first, 'npm test'
    assert_includes first, 'translate(240 220)'
    assert_includes first, 'fill="#d9e3df"'
    refute_equal first, later
  end

  def test_default_model_matches_the_workflow_model
    workflow = File.read(File.expand_path('../.github/workflows/generate-requested-gif.yml', __dir__))

    assert_equal 'qwen2.5:0.5b', RequestGif::DEFAULT_MODEL
    assert_includes workflow, "OLLAMA_MODEL: #{RequestGif::DEFAULT_MODEL}"
  end

  def test_ci_default_is_text_to_gif_without_video_input
    workflow = File.read(File.expand_path('../.github/workflows/generate-requested-gif.yml', __dir__))

    assert_includes workflow, 'name: Text prompt to GIF (download artifact)'
    assert_includes workflow, 'prompt:'
    assert_includes workflow, 'required: true'
    assert_includes workflow, 'default: "A shining n-bit sunflower'
    refute_includes workflow, 'video_path'
  end
end
