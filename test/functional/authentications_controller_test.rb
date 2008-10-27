require 'test_helper'

class AuthenticationsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:authentications)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_authentication
    assert_difference('Authentication.count') do
      post :create, :authentication => { }
    end

    assert_redirected_to authentication_path(assigns(:authentication))
  end

  def test_should_show_authentication
    get :show, :id => authentications(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => authentications(:one).id
    assert_response :success
  end

  def test_should_update_authentication
    put :update, :id => authentications(:one).id, :authentication => { }
    assert_redirected_to authentication_path(assigns(:authentication))
  end

  def test_should_destroy_authentication
    assert_difference('Authentication.count', -1) do
      delete :destroy, :id => authentications(:one).id
    end

    assert_redirected_to authentications_path
  end
end
