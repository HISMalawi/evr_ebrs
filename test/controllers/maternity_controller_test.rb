require 'test_helper'

class MaternityControllerTest < ActionController::TestCase
  test "should get create_from_maternity" do
    get :create_from_maternity
    assert_response :success
  end

end
