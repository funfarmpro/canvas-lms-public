# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class QuestionBanksApiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index, :index_with_questions, :questions_standalone]
  before_action :require_context, only: [:questions]
  before_action :authenticate_by_api_key_or_user, only: [:index, :index_with_questions, :questions_standalone]

  # @API List questions in a classic question bank (context-based)
  #
  # Returns paginated classic question bank questions in the same structure as
  # the web JSON endpoint, including assessment_question.question_data with
  # answers[].weight and points_possible.
  #
  # @argument inherited [Boolean]
  #   Search inherited banks for this context as well.
  #
  # @returns {"pages": Integer, "questions": [AssessmentQuestion]}
  def questions
    find_bank(params[:question_bank_id], params[:inherited] == "1") do
      questions = @bank.assessment_questions.active
      questions_url = request.original_url
      questions = Api.paginate(questions, self, questions_url, default_per_page: 50)
      render json: { pages: questions.total_pages, questions: questions }
    end
  end

  # @API List all accessible question banks
  #
  # Authenticate via X-API-Key header or Bearer token.
  # With API key: returns all banks (admin-level access).
  # With Bearer token: admins see all banks, teachers see their courses' banks.
  #
  # @returns [AssessmentQuestionBank]
  def index
    banks = accessible_banks
    render json: banks.map { |b| bank_json(b) }
  end

  # @API List all accessible question banks with questions
  #
  # Authenticate via X-API-Key header or Bearer token.
  # Each bank includes a "questions" array with full question_data.
  #
  # @returns [AssessmentQuestionBank]
  def index_with_questions
    banks = accessible_banks.preload(:assessment_questions)
    render json: banks.map { |b|
      bank_json(b).merge(
        "questions" => b.assessment_questions.active.as_json
      )
    }
  end

  # @API List questions in a question bank (standalone)
  #
  # Authenticate via X-API-Key header or Bearer token.
  # Returns paginated questions from a bank by bank ID.
  #
  # @returns {"pages": Integer, "questions": [AssessmentQuestion]}
  def questions_standalone
    bank = AssessmentQuestionBank.active.find(params[:question_bank_id])
    if @api_key_auth || account_admin? || bank.grants_right?(@current_user, session, :read)
      questions = bank.assessment_questions.active
      questions = Api.paginate(questions, self, request.original_url, default_per_page: 50)
      render json: { pages: questions.total_pages, questions: questions }
    else
      render_unauthorized_action
    end
  end

  private

  def authenticate_by_api_key_or_user
    api_key = request.headers["X-API-Key"]
    expected_key = ENV["QUESTION_BANKS_API_KEY"].presence

    Rails.logger.info("[QB-API-AUTH] api_key present: #{api_key.present?}, expected_key present: #{expected_key.present?}, match: #{expected_key && api_key == expected_key}")
    Rails.logger.info("[QB-API-AUTH] api_key=#{api_key.inspect}, expected_key=#{expected_key.inspect}")

    if expected_key && api_key == expected_key
      @api_key_auth = true
      Rails.logger.info("[QB-API-AUTH] Authenticated via API key")
      return
    end

    @api_key_auth = false

    if api_key.present?
      Rails.logger.warn("[QB-API-AUTH] Invalid API key provided")
      render json: { error: "Invalid API key" }, status: :unauthorized
      return
    end

    Rails.logger.info("[QB-API-AUTH] No API key, falling back to require_user")
    require_user
  end

  def accessible_banks
    if @api_key_auth || account_admin?
      AssessmentQuestionBank.active
        .where(context_type: "Course")
        .order(:title)
    else
      course_ids = @current_user.enrollments.active
                     .where(type: %w[TeacherEnrollment TaEnrollment DesignerEnrollment])
                     .pluck(:course_id)
      AssessmentQuestionBank.active
        .where(context_type: "Course", context_id: course_ids)
        .order(:title)
    end
  end

  def account_admin?
    return false unless @current_user

    @_account_admin ||= begin
      Account.site_admin.account_users.active.where(user_id: @current_user.id).exists? ||
        Account.default.account_users.active.where(user_id: @current_user.id).exists?
    end
  end

  def bank_json(bank)
    bank.as_json(methods: [:assessment_question_count]).merge(
      "context_name" => bank.context&.name
    )
  end
end
