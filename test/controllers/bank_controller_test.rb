require 'test_helper'

class BankControllerTest < ActionController::TestCase

  test "should get teller" do
    get :teller
    assert_response :success
  end

  test "should get vault with the right password" do
    @request.headers["Authorization"] = "Token token=secret"
    get :vault
    assert_response :success
  end

  test "should not get vault with the wrong password" do
    @request.headers["Authorization"] = "Token token=tecret"
    get :vault
    assert_response :unauthorized
  end

end
